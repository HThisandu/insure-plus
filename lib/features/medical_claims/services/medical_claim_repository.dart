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

/// Production repository wired directly to the shared backend services:
/// - `lib/services/claims_service.dart` (`submitClaim`, `getUserClaims`,
///   `addClaimDocument`, `removeClaimDocument`)
/// - `lib/services/storage_service.dart` (`uploadClaimDocument`,
///   `downloadClaimDocument`, `deleteClaimDocument` on private Supabase bucket
///   `claim-documents`)
class FirestoreMedicalClaimRepository implements MedicalClaimRepository {
  FirestoreMedicalClaimRepository({
    this._claimsService,
    this._storageService,
    this._firestore,
    this._auth,
  });

  static const String claimsCollection = 'claims';

  final ClaimsService? _claimsService;
  final StorageService? _storageService;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  ClaimsService get _claims => _claimsService ?? ClaimsService();
  StorageService get _storage => _storageService ?? StorageService();
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;

  List<MedicalClaim> _parseMedicalDocs(
    Iterable<QueryDocumentSnapshot<Object?>> docs,
  ) {
    final results = <MedicalClaim>[];
    for (final doc in docs) {
      final raw = doc.data();
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final claimType = (map['claimType'] as String?)?.trim() ?? '';
      if (claimType != MedicalClaim.defaultClaimType) continue;
      results.add(MedicalClaim.fromMap(map, documentId: doc.id));
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Stream<List<MedicalClaim>> watchClaims(String userId) async* {
    // 1. Initial load via existing backend ClaimsService.getUserClaims()
    final initialSnapshot = await _claims.getUserClaims();
    yield _parseMedicalDocs(initialSnapshot.docs);

    // 2. Real-time updates for status changes made by Operations/Admin
    final activeUid = _firebaseAuth.currentUser?.uid ?? userId;
    if (activeUid.trim().isEmpty) return;

    yield* _db
        .collection(claimsCollection)
        .where('userId', isEqualTo: activeUid)
        .snapshots()
        .map((snapshot) => _parseMedicalDocs(snapshot.docs));
  }

  @override
  Future<MedicalClaim> submitClaim(
    MedicalClaim claim, {
    String? localBillFilePath,
    List<PendingMedicalAttachment> attachments = const [],
  }) async {
    final activeUid = _firebaseAuth.currentUser?.uid ?? claim.userId;

    // 1. Create the claim in Firestore via ClaimsService.submitClaim()
    final claimId = await _claims.submitClaim(
      policyId: claim.policyId,
      claimType: MedicalClaim.defaultClaimType,
      claimAmount: claim.claimAmount,
      description: claim.toFirestoreDescription(),
    );

    // 2. Gather any local medical bills / reports to upload to Supabase
    final pendingUploads = _collectPendingAttachments(
      localBillFilePath: localBillFilePath,
      attachments: attachments,
    );

    final uploadedDocuments = <MedicalBillDocument>[...claim.documents];

    for (final item in pendingUploads) {
      final fileBytes = await _readAttachmentBytes(item);
      // Upload binary to private Supabase `claim-documents` bucket
      final storagePath = await _storage.uploadClaimDocument(
        claimId: claimId,
        fileName: item.fileName,
        fileBytes: fileBytes,
        contentType: item.contentType,
      );

      // Persist document metadata to Firestore via ClaimsService.addClaimDocument()
      await _claims.addClaimDocument(
        claimId: claimId,
        documentType: item.documentType,
        fileName: item.fileName,
        storagePath: storagePath,
      );

      final now = DateTime.now();
      uploadedDocuments.add(
        MedicalBillDocument(
          documentId: 'DOC-${now.microsecondsSinceEpoch}',
          documentType: item.documentType,
          fileName: item.fileName,
          storagePath: storagePath,
          uploadedAt: now,
          localPreviewPath: item.localPath,
        ),
      );
    }

    final refreshed = await getClaimById(claimId);
    if (refreshed != null) {
      return refreshed;
    }

    return claim.copyWith(
      claimId: claimId,
      userId: activeUid,
      claimType: MedicalClaim.defaultClaimType,
      status: MedicalClaimStatus.submitted,
      documents: uploadedDocuments,
    );
  }

  @override
  Future<MedicalClaim?> getClaimById(String claimId) async {
    final snapshot = await _db.collection(claimsCollection).doc(claimId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return MedicalClaim.fromMap(data, documentId: snapshot.id);
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
        localPreviewPath.trim().isNotEmpty &&
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
    if (claimId.trim().isNotEmpty && documentId.trim().isNotEmpty) {
      await _claims.removeClaimDocument(
        claimId: claimId,
        documentId: documentId,
      );
    } else if (storagePath.trim().isNotEmpty) {
      await _storage.deleteClaimDocument(storagePath: storagePath);
    }
  }

  Future<Uint8List> _readAttachmentBytes(PendingMedicalAttachment item) async {
    if (item.bytes != null) return item.bytes!;
    final path = item.localPath?.trim();
    if (path == null || path.isEmpty) {
      throw const FileSystemException('No medical bill file path provided.');
    }
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException(
        'Selected medical document could not be found.',
        path,
      );
    }
    return file.readAsBytes();
  }
}

List<PendingMedicalAttachment> _collectPendingAttachments({
  String? localBillFilePath,
  List<PendingMedicalAttachment> attachments = const [],
}) {
  final combined = <PendingMedicalAttachment>[...attachments];
  final singlePath = localBillFilePath?.trim();
  if (singlePath != null && singlePath.isNotEmpty) {
    final alreadyIncluded = combined.any((a) => a.localPath == singlePath);
    if (!alreadyIncluded) {
      final segments = singlePath
          .split(RegExp(r'[/\\]'))
          .where((part) => part.isNotEmpty)
          .toList();
      final name = segments.isNotEmpty ? segments.last : 'medical_bill.jpg';
      combined.add(
        PendingMedicalAttachment(
          fileName: name,
          documentType: 'Medical Bill',
          localPath: singlePath,
        ),
      );
    }
  }
  return combined;
}

class InMemoryMedicalClaimRepository implements MedicalClaimRepository {
  InMemoryMedicalClaimRepository({
    Iterable<MedicalClaim>? initialClaims,
    this.simulatedDelay = const Duration(milliseconds: 250),
  }) : _claims = {
         for (final claim in initialClaims ?? _defaultSampleClaims())
           claim.claimId: claim,
       };

  final Duration simulatedDelay;
  final Map<String, MedicalClaim> _claims;
  final Map<String, Uint8List> _storedBytes = {};
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();
  int _sequence = 4;

  static List<MedicalClaim> _defaultSampleClaims() => [
    MedicalClaim(
      claimId: 'MED-2026-001',
      userId: 'DEMO-USER-01',
      policyId: 'MEDICAL-001',
      claimAmount: 185500.00,
      description:
          'Inpatient surgical admission and 3-day ward stay for laparoscopic appendectomy.',
      status: MedicalClaimStatus.underReview,
      documents: [
        MedicalBillDocument(
          documentId: 'DOC-MED-001',
          documentType: 'Hospital final bill',
          fileName: 'asiri-surgical-final-bill.pdf',
          storagePath:
              'DEMO-USER-01/MED-2026-001/1763452200000_asiri-surgical-final-bill.pdf',
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
      description:
          'Outpatient specialist consultation, ECG screening, and prescribed cardiac medication.',
      status: MedicalClaimStatus.approved,
      documents: [
        MedicalBillDocument(
          documentId: 'DOC-MED-002',
          documentType: 'Medical Bill',
          fileName: 'nawaloka-opd-receipt.jpg',
          storagePath:
              'DEMO-USER-01/MED-2026-002/1762940700000_nawaloka-opd-receipt.jpg',
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
      description:
          'Pediatric diagnostic lab panel, chest X-ray, and MRI scan requested by consultant.',
      status: MedicalClaimStatus.submitted,
      documents: [
        MedicalBillDocument(
          documentId: 'DOC-MED-003',
          documentType: 'Medical Report',
          fileName: 'lanka-hospitals-diagnostics-bill.jpg',
          storagePath:
              'DEMO-USER-01/MED-2026-003/1763612100000_lanka-hospitals-diagnostics-bill.jpg',
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

  List<MedicalClaim> _claimsForUser(String userId) {
    final matches = _claims.values
        .where(
          (claim) =>
              claim.claimType == MedicalClaim.defaultClaimType &&
              claim.userId == userId,
        )
        .toList();
    matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches;
  }

  @override
  Stream<List<MedicalClaim>> watchClaims(String userId) async* {
    yield _claimsForUser(userId);
    await for (final _ in _changesController.stream) {
      yield _claimsForUser(userId);
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

    final resolvedClaimId = claim.claimId.trim().isNotEmpty
        ? claim.claimId.trim()
        : 'MED-${DateTime.now().year}-${(_sequence++).toString().padLeft(3, '0')}';

    final updatedDocuments = List<MedicalBillDocument>.from(claim.documents);
    final pendingUploads = _collectPendingAttachments(
      localBillFilePath: localBillFilePath,
      attachments: attachments,
    );

    for (var i = 0; i < pendingUploads.length; i++) {
      final item = pendingUploads[i];
      final now = DateTime.now();
      final safeName = item.fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final storagePath =
          '${claim.userId}/$resolvedClaimId/${now.millisecondsSinceEpoch}_${i}_$safeName';
      if (item.bytes != null) {
        _storedBytes[storagePath] = item.bytes!;
      }

      updatedDocuments.add(
        MedicalBillDocument(
          documentId: 'DOC-${now.millisecondsSinceEpoch}-$i',
          documentType: item.documentType,
          fileName: item.fileName,
          storagePath: storagePath,
          uploadedAt: now,
          localPreviewPath: item.localPath,
        ),
      );
    }

    final savedClaim = claim.copyWith(
      claimId: resolvedClaimId,
      claimType: MedicalClaim.defaultClaimType,
      documents: updatedDocuments,
    );

    _claims[resolvedClaimId] = savedClaim;
    if (!_changesController.isClosed) {
      _changesController.add(null);
    }
    return savedClaim;
  }

  @override
  Future<MedicalClaim?> getClaimById(String claimId) async {
    return _claims[claimId];
  }

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
        localPreviewPath.trim().isNotEmpty &&
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
    final existing = _claims[claimId];
    if (existing == null) return;

    final remaining = existing.documents
        .where((doc) => doc.documentId != documentId)
        .toList();
    _claims[claimId] = existing.copyWith(documents: remaining);
    if (!_changesController.isClosed) {
      _changesController.add(null);
    }
  }

  void dispose() {
    if (!_changesController.isClosed) {
      _changesController.close();
    }
  }
}
