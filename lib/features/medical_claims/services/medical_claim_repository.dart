import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/medical_bill_document.dart';
import '../models/medical_claim.dart';
import '../models/medical_claim_status.dart';

abstract class MedicalClaimRepository {
  Stream<List<MedicalClaim>> watchClaims(String userId);

  Future<MedicalClaim> submitClaim(
    MedicalClaim claim, {
    String? localBillFilePath,
  });

  Future<MedicalClaim?> getClaimById(String claimId);
}

class FirestoreMedicalClaimRepository implements MedicalClaimRepository {
  FirestoreMedicalClaimRepository({
    this._firestore,
    this._storage,
  });

  static const String claimsCollection = 'claims';

  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _fileStorage => _storage ?? FirebaseStorage.instance;

  @override
  Stream<List<MedicalClaim>> watchClaims(String userId) {
    return _db
        .collection(claimsCollection)
        .where('claimType', isEqualTo: MedicalClaim.defaultClaimType)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final claims = snapshot.docs
              .map(
                (doc) => MedicalClaim.fromMap(doc.data(), documentId: doc.id),
              )
              .toList();
          claims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return claims;
        });
  }

  @override
  Future<MedicalClaim> submitClaim(
    MedicalClaim claim, {
    String? localBillFilePath,
  }) async {
    final collection = _db.collection(claimsCollection);
    final docRef = claim.claimId.trim().isNotEmpty
        ? collection.doc(claim.claimId.trim())
        : collection.doc();
    final resolvedClaimId = docRef.id;

    final updatedDocuments = List<MedicalBillDocument>.from(claim.documents);

    if (localBillFilePath != null && localBillFilePath.trim().isNotEmpty) {
      final uploadedDoc = await _uploadBillFile(
        claimId: resolvedClaimId,
        localFilePath: localBillFilePath.trim(),
      );
      updatedDocuments.add(uploadedDoc);
    }

    final claimToSave = claim.copyWith(
      claimId: resolvedClaimId,
      claimType: MedicalClaim.defaultClaimType,
      documents: updatedDocuments,
    );

    await docRef.set(claimToSave.toMap());
    return claimToSave;
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

  Future<MedicalBillDocument> _uploadBillFile({
    required String claimId,
    required String localFilePath,
  }) async {
    final file = File(localFilePath);
    if (!file.existsSync()) {
      throw FileSystemException(
        'Selected medical bill file could not be found.',
        localFilePath,
      );
    }

    final fileName = _extractFileName(localFilePath);
    final storagePath = 'medical_claims/$claimId/$fileName';
    final storageRef = _fileStorage.ref().child(storagePath);

    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();
    final now = DateTime.now();

    return MedicalBillDocument(
      documentId: 'DOC-${now.millisecondsSinceEpoch}',
      documentType: 'Medical bill',
      fileName: fileName,
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      uploadedAt: now,
    );
  }

  static String _extractFileName(String path) {
    final segments = path
        .split(RegExp(r'[/\\]'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (segments.isEmpty) {
      return 'medical_bill_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
    return segments.last;
  }
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
          storagePath: 'medical_claims/MED-2026-001/asiri-surgical-final-bill.pdf',
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
          documentType: 'Medical bill',
          fileName: 'nawaloka-opd-receipt.jpg',
          storagePath: 'medical_claims/MED-2026-002/nawaloka-opd-receipt.jpg',
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
          documentType: 'Lab invoice',
          fileName: 'lanka-hospitals-diagnostics-bill.jpg',
          storagePath:
              'medical_claims/MED-2026-003/lanka-hospitals-diagnostics-bill.jpg',
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
  }) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    final resolvedClaimId = claim.claimId.trim().isNotEmpty
        ? claim.claimId.trim()
        : 'MED-${DateTime.now().year}-${(_sequence++).toString().padLeft(3, '0')}';

    final updatedDocuments = List<MedicalBillDocument>.from(claim.documents);

    if (localBillFilePath != null && localBillFilePath.trim().isNotEmpty) {
      final cleanPath = localBillFilePath.trim();
      final segments = cleanPath
          .split(RegExp(r'[/\\]'))
          .where((part) => part.isNotEmpty)
          .toList();
      final fileName = segments.isNotEmpty ? segments.last : 'medical_bill.jpg';
      final now = DateTime.now();

      updatedDocuments.add(
        MedicalBillDocument(
          documentId: 'DOC-${now.millisecondsSinceEpoch}',
          documentType: 'Medical bill',
          fileName: fileName,
          storagePath: 'medical_claims/$resolvedClaimId/$fileName',
          downloadUrl: cleanPath,
          uploadedAt: now,
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

  void dispose() {
    if (!_changesController.isClosed) {
      _changesController.close();
    }
  }
}
