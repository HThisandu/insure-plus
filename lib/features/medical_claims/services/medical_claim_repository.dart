import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../services/claims_service.dart';
import '../../../services/storage_service.dart';
import '../models/medical_bill_document.dart';
import '../models/medical_claim.dart';
import '../models/medical_claim_status.dart';

abstract class MedicalClaimRepository {
  Stream<List<MedicalClaim>> watchClaims(String userId);

  Future<MedicalClaim> submitClaim(
    MedicalClaim claim, {
    String? localBillFilePath,
    List<PendingMedicalAttachment> attachments = const [],
  });

  Future<MedicalClaim?> getClaimById(String claimId);

  Future<Uint8List?> downloadDocument({
    required String storagePath,
    String? localPreviewPath,
  });

  Future<void> deleteDocument({
    required String claimId,
    required String documentId,
    required String storagePath,
  });
}

// Connects Medical Claims to ClaimsService (Firestore) and StorageService (Supabase)
class FirestoreMedicalClaimRepository implements MedicalClaimRepository {
  FirestoreMedicalClaimRepository({
    this.claimsService,
    this.storageService,
  });

  final ClaimsService? claimsService;
  final StorageService? storageService;

  ClaimsService get _claims => claimsService ?? ClaimsService();
  StorageService get _storage => storageService ?? StorageService();

  List<MedicalClaim> _mapSnapshotToMedicalClaims(
    List<QueryDocumentSnapshot<Object?>> docs,
  ) {
    final list = <MedicalClaim>[];
    for (final doc in docs) {
      final raw = doc.data();
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      if (map['claimType'] != MedicalClaim.defaultClaimType) continue;
      list.add(MedicalClaim.fromMap(map, documentId: doc.id));
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Stream<List<MedicalClaim>> watchClaims(String userId) async* {
    // 1. Load initial user claims using ClaimsService
    final initial = await _claims.getUserClaims();
    yield _mapSnapshotToMedicalClaims(initial.docs);

    // 2. Listen for status updates in Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid ?? userId;
    if (uid.trim().isEmpty) return;

    yield* FirebaseFirestore.instance
        .collection('claims')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => _mapSnapshotToMedicalClaims(snapshot.docs));
  }

  @override
  Future<MedicalClaim> submitClaim(
    MedicalClaim claim, {
    String? localBillFilePath,
    List<PendingMedicalAttachment> attachments = const [],
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? claim.userId;

    // 1. Save claim details in Firestore
    final claimId = await _claims.submitClaim(
      policyId: claim.policyId,
      claimType: MedicalClaim.defaultClaimType,
      claimAmount: claim.claimAmount,
      description: claim.toFirestoreDescription(),
    );

    // 2. Upload bills/reports to Supabase `claim-documents` bucket
    final filesToUpload = _mergeAttachments(localBillFilePath, attachments);
    final savedDocs = <MedicalBillDocument>[...claim.documents];

    for (final file in filesToUpload) {
      final bytes =
          file.bytes ?? await File(file.localPath!).readAsBytes();

      final storagePath = await _storage.uploadClaimDocument(
        claimId: claimId,
        fileName: file.fileName,
        fileBytes: bytes,
        contentType: file.contentType,
      );

      // 3. Save document metadata in Firestore
      await _claims.addClaimDocument(
        claimId: claimId,
        documentType: file.documentType,
        fileName: file.fileName,
        storagePath: storagePath,
      );

      final now = DateTime.now();
      savedDocs.add(
        MedicalBillDocument(
          documentId: 'DOC-${now.millisecondsSinceEpoch}',
          documentType: file.documentType,
          fileName: file.fileName,
          storagePath: storagePath,
          uploadedAt: now,
          localPreviewPath: file.localPath,
        ),
      );
    }

    final fromDb = await getClaimById(claimId);
    if (fromDb != null) return fromDb;

    return claim.copyWith(
      claimId: claimId,
      userId: uid,
      status: MedicalClaimStatus.submitted,
      documents: savedDocs,
    );
  }

  @override
  Future<MedicalClaim?> getClaimById(String claimId) async {
    final doc = await FirebaseFirestore.instance
        .collection('claims')
        .doc(claimId)
        .get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return MedicalClaim.fromMap(data, documentId: doc.id);
  }

  @override
  Future<Uint8List?> downloadDocument({
    required String storagePath,
    String? localPreviewPath,
  }) async {
    if (storagePath.trim().isNotEmpty) {
      return _storage.downloadClaimDocument(storagePath: storagePath);
    }
    if (!kIsWeb &&
        localPreviewPath != null &&
        File(localPreviewPath).existsSync()) {
      return File(localPreviewPath).readAsBytes();
    }
    return null;
  }

  @override
  Future<void> deleteDocument({
    required String claimId,
    required String documentId,
    required String storagePath,
  }) async {
    if (claimId.isNotEmpty && documentId.isNotEmpty) {
      await _claims.removeClaimDocument(
        claimId: claimId,
        documentId: documentId,
      );
    } else if (storagePath.isNotEmpty) {
      await _storage.deleteClaimDocument(storagePath: storagePath);
    }
  }
}

List<PendingMedicalAttachment> _mergeAttachments(
  String? singlePath,
  List<PendingMedicalAttachment> attachments,
) {
  final list = <PendingMedicalAttachment>[...attachments];
  if (singlePath != null && singlePath.trim().isNotEmpty) {
    final path = singlePath.trim();
    final exists = list.any((item) => item.localPath == path);
    if (!exists) {
      final name = path.split('/').last.split('\\').last;
      list.add(
        PendingMedicalAttachment(
          fileName: name.isEmpty ? 'medical_bill.jpg' : name,
          localPath: path,
        ),
      );
    }
  }
  return list;
}

// Local repository with Sri Lankan sample claims for testing & preview
class InMemoryMedicalClaimRepository implements MedicalClaimRepository {
  InMemoryMedicalClaimRepository({
    Iterable<MedicalClaim>? initialClaims,
    this.simulatedDelay = const Duration(milliseconds: 250),
  }) : _claims = {
         for (final claim in initialClaims ?? _sampleClaims())
           claim.claimId: claim,
       };

  final Duration simulatedDelay;
  final Map<String, MedicalClaim> _claims;
  final Map<String, Uint8List> _storedBytes = {};
  final StreamController<void> _controller = StreamController<void>.broadcast();
  int _counter = 4;

  static List<MedicalClaim> _sampleClaims() => [
    MedicalClaim(
      claimId: 'MED-2026-001',
      userId: 'DEMO-USER-01',
      policyId: 'MEDICAL-001',
      claimAmount: 185500.00,
      description:
          'Inpatient surgical admission and 3-day ward stay for appendectomy.',
      status: MedicalClaimStatus.underReview,
      documents: [
        MedicalBillDocument(
          documentId: 'DOC-MED-001',
          documentType: 'Hospital final bill',
          fileName: 'asiri-surgical-final-bill.pdf',
          storagePath: 'DEMO-USER-01/MED-2026-001/asiri-surgical-final-bill.pdf',
          uploadedAt: DateTime(2026, 11, 18, 10, 30),
        ),
      ],
      createdAt: DateTime(2026, 11, 18, 10, 30),
      patientName: 'Kasun Perera',
      patientRelationship: 'Self',
      hospitalName: 'Asiri Hospital',
      treatmentType: 'Inpatient',
      admissionDate: DateTime(2026, 11, 14),
      dischargeDate: DateTime(2026, 11, 17),
      billNumber: 'ASH-2026-88412',
      billDate: DateTime(2026, 11, 17),
    ),
    MedicalClaim(
      claimId: 'MED-2026-002',
      userId: 'DEMO-USER-01',
      policyId: 'MEDICAL-001',
      claimAmount: 24750.00,
      description: 'Outpatient specialist consultation and ECG screening.',
      status: MedicalClaimStatus.approved,
      documents: [
        MedicalBillDocument(
          documentId: 'DOC-MED-002',
          documentType: 'Medical Bill',
          fileName: 'nawaloka-opd-receipt.jpg',
          storagePath: 'DEMO-USER-01/MED-2026-002/nawaloka-opd-receipt.jpg',
          uploadedAt: DateTime(2026, 11, 12, 15, 15),
        ),
      ],
      createdAt: DateTime(2026, 11, 12, 15, 15),
      patientName: 'Dilini Perera',
      patientRelationship: 'Spouse',
      hospitalName: 'Nawaloka Hospital',
      treatmentType: 'Outpatient',
      billNumber: 'NWL-2026-44109',
      billDate: DateTime(2026, 11, 11),
    ),
    MedicalClaim(
      claimId: 'MED-2026-003',
      userId: 'DEMO-USER-01',
      policyId: 'MEDICAL-001',
      claimAmount: 42300.00,
      description: 'Diagnostic blood panel and MRI scan.',
      status: MedicalClaimStatus.submitted,
      documents: [
        MedicalBillDocument(
          documentId: 'DOC-MED-003',
          documentType: 'Medical Report',
          fileName: 'lanka-hospitals-diagnostics-bill.jpg',
          storagePath:
              'DEMO-USER-01/MED-2026-003/lanka-hospitals-diagnostics-bill.jpg',
          uploadedAt: DateTime(2026, 11, 20, 9, 45),
        ),
      ],
      createdAt: DateTime(2026, 11, 20, 9, 45),
      patientName: 'Senuth Perera',
      patientRelationship: 'Child',
      hospitalName: 'Lanka Hospitals',
      treatmentType: 'Lab & Diagnostics',
      billNumber: 'LKH-2026-19205',
      billDate: DateTime(2026, 11, 19),
    ),
  ];

  List<MedicalClaim> _forUser(String userId) {
    final list = _claims.values
        .where((c) => c.userId == userId && c.claimType == 'Medical')
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Stream<List<MedicalClaim>> watchClaims(String userId) async* {
    yield _forUser(userId);
    await for (final _ in _controller.stream) {
      yield _forUser(userId);
    }
  }

  @override
  Future<MedicalClaim> submitClaim(
    MedicalClaim claim, {
    String? localBillFilePath,
    List<PendingMedicalAttachment> attachments = const [],
  }) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    final id = claim.claimId.trim().isNotEmpty
        ? claim.claimId.trim()
        : 'MED-${DateTime.now().year}-${(_counter++).toString().padLeft(3, '0')}';

    final docs = List<MedicalBillDocument>.from(claim.documents);
    final files = _mergeAttachments(localBillFilePath, attachments);

    for (var i = 0; i < files.length; i++) {
      final item = files[i];
      final now = DateTime.now();
      final path = '${claim.userId}/$id/${now.millisecondsSinceEpoch}_${item.fileName}';
      if (item.bytes != null) {
        _storedBytes[path] = item.bytes!;
      }
      docs.add(
        MedicalBillDocument(
          documentId: 'DOC-${now.millisecondsSinceEpoch}-$i',
          documentType: item.documentType,
          fileName: item.fileName,
          storagePath: path,
          uploadedAt: now,
          localPreviewPath: item.localPath,
        ),
      );
    }

    final saved = claim.copyWith(claimId: id, documents: docs);
    _claims[id] = saved;
    if (!_controller.isClosed) _controller.add(null);
    return saved;
  }

  @override
  Future<MedicalClaim?> getClaimById(String claimId) async => _claims[claimId];

  @override
  Future<Uint8List?> downloadDocument({
    required String storagePath,
    String? localPreviewPath,
  }) async {
    if (_storedBytes.containsKey(storagePath)) {
      return _storedBytes[storagePath];
    }
    if (!kIsWeb &&
        localPreviewPath != null &&
        File(localPreviewPath).existsSync()) {
      return File(localPreviewPath).readAsBytes();
    }
    return null;
  }

  @override
  Future<void> deleteDocument({
    required String claimId,
    required String documentId,
    required String storagePath,
  }) async {
    _storedBytes.remove(storagePath);
    final claim = _claims[claimId];
    if (claim == null) return;
    final remaining = claim.documents
        .where((d) => d.documentId != documentId)
        .toList();
    _claims[claimId] = claim.copyWith(documents: remaining);
    if (!_controller.isClosed) _controller.add(null);
  }

  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}
