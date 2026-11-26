import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:insure_plus/features/medical_claims/medical_claims.dart';

void main() {
  group('MedicalClaimStatus', () {
    test('fromValue parses canonical values, labels, and fallback', () {
      expect(
        MedicalClaimStatus.fromValue('Submitted'),
        MedicalClaimStatus.submitted,
      );
      expect(
        MedicalClaimStatus.fromValue('UnderReview'),
        MedicalClaimStatus.underReview,
      );
      expect(
        MedicalClaimStatus.fromValue('Under review'),
        MedicalClaimStatus.underReview,
      );
      expect(
        MedicalClaimStatus.fromValue('MoreInfoRequired'),
        MedicalClaimStatus.moreInfoRequired,
      );
      expect(
        MedicalClaimStatus.fromValue('Approved'),
        MedicalClaimStatus.approved,
      );
      expect(
        MedicalClaimStatus.fromValue('Rejected'),
        MedicalClaimStatus.rejected,
      );
      expect(MedicalClaimStatus.fromValue(''), MedicalClaimStatus.submitted);
    });
  });

  group('Firestore 9-field schema & Supabase 5-field document metadata', () {
    test(
      'MedicalClaim.toMap emits strictly the 9 Firestore keys and round-trips all medical fields',
      () {
        final original = MedicalClaim(
          claimId: 'MED-2026-999',
          userId: 'USER-10',
          policyId: 'MEDICAL-001',
          claimAmount: 65400.50,
          description: 'Outpatient ENT consultation and endoscopy.',
          status: MedicalClaimStatus.underReview,
          documents: [
            MedicalBillDocument(
              documentId: 'DOC-1',
              documentType: 'Medical Bill',
              fileName: 'ent-bill.jpg',
              storagePath: 'USER-10/MED-2026-999/1763612100000_ent-bill.jpg',
              uploadedAt: DateTime(2026, 11, 20, 12, 0),
            ),
          ],
          createdAt: DateTime(2026, 11, 20, 12, 0),
          patientName: 'Nimal Silva',
          patientRelationship: 'Self',
          hospitalName: 'Durdans Hospital',
          treatmentType: 'Outpatient',
          admissionDate: DateTime(2026, 11, 19),
          dischargeDate: DateTime(2026, 11, 19),
          billNumber: 'DRD-10293',
          billDate: DateTime(2026, 11, 19),
        );

        final map = original.toMap();
        expect(
          map.keys.toSet(),
          equals({
            'claimId',
            'userId',
            'policyId',
            'claimType',
            'claimAmount',
            'description',
            'status',
            'documents',
            'createdAt',
          }),
        );

        final docMap = (map['documents'] as List).first as Map<String, dynamic>;
        expect(
          docMap.keys.toSet(),
          equals({
            'documentId',
            'documentType',
            'fileName',
            'storagePath',
            'uploadedAt',
          }),
        );

        final restored = MedicalClaim.fromMap(map);
        expect(restored.claimId, 'MED-2026-999');
        expect(restored.claimType, 'Medical');
        expect(restored.claimAmount, 65400.50);
        expect(restored.description, 'Outpatient ENT consultation and endoscopy.');
        expect(restored.patientName, 'Nimal Silva');
        expect(restored.patientRelationship, 'Self');
        expect(restored.hospitalName, 'Durdans Hospital');
        expect(restored.treatmentType, 'Outpatient');
        expect(restored.admissionDate, DateTime(2026, 11, 19));
        expect(restored.dischargeDate, DateTime(2026, 11, 19));
        expect(restored.billNumber, 'DRD-10293');
        expect(restored.billDate, DateTime(2026, 11, 19));
        expect(restored.documents.single.fileName, 'ent-bill.jpg');
      },
    );

    test('OcrBillData parses map and formatLkr formats LKR amounts', () {
      final ocr = OcrBillData.fromMap({
        'hospitalName': 'Asiri Hospital',
        'billNumber': 'ASH-7721',
        'amount': '19,250.00',
        'billDate': '2026-11-21T00:00:00.000',
        'localImagePath': '/tmp/bill.jpg',
      });

      expect(ocr.hasExtractedFields, isTrue);
      expect(ocr.hasImage, isTrue);
      expect(ocr.amount, 19250.00);
      expect(formatLkr(185500.5), 'LKR 185,500.50');
    });
  });

  group('MedicalClaimService & InMemoryMedicalClaimRepository', () {
    late InMemoryMedicalClaimRepository repository;
    late MedicalClaimService service;

    setUp(() async {
      repository = InMemoryMedicalClaimRepository(simulatedDelay: Duration.zero);
      service = MedicalClaimService(
        repository: repository,
        userId: 'DEMO-USER-01',
      );
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      service.dispose();
      repository.dispose();
    });

    test('supports grouped Figma filters (All, In progress, Closed) and search', () {
      expect(service.claims.length, 3);
      expect(service.inProgressCount, 2);
      expect(service.closedCount, 1);

      service.setViewFilter(MedicalClaimsViewFilter.inProgress);
      expect(service.filteredClaims.length, 2);

      service.setViewFilter(MedicalClaimsViewFilter.closed);
      expect(service.filteredClaims.length, 1);
      expect(service.filteredClaims.single.hospitalName, 'Nawaloka Hospital');

      service.setViewFilter(MedicalClaimsViewFilter.all);
      service.setSearchQuery('ASH-2026-88412');
      expect(service.filteredClaims.single.claimId, 'MED-2026-001');
    });

    test('submits claim, downloads bytes, and deletes document cleanly', () async {
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final created = await service.submitMedicalClaim(
        userId: 'DEMO-USER-01',
        policyId: 'MEDICAL-001',
        claimAmount: 14500.00,
        description: 'Pharmacy prescription refill.',
        patientName: 'Kasun Perera',
        patientRelationship: 'Self',
        hospitalName: 'Hemas Hospital',
        treatmentType: 'Pharmacy',
        attachments: [
          PendingMedicalAttachment(
            fileName: 'hemas-receipt.jpg',
            documentType: 'Medical Bill',
            bytes: sampleBytes,
            fileSizeBytes: sampleBytes.length,
          ),
        ],
      );

      expect(created, isNotNull);
      expect(created!.documents.length, 1);
      final doc = created.documents.single;

      final downloaded = await service.downloadClaimDocument(doc);
      expect(downloaded, equals(sampleBytes));

      final removed = await service.deleteClaimDocument(
        claimId: created.claimId,
        document: doc,
      );
      expect(removed, isTrue);
      expect(service.findClaim(created.claimId)!.documents, isEmpty);
    });
  });
}
