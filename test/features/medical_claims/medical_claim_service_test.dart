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
        MedicalClaimStatus.fromValue('more_info_required'),
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
      expect(
        MedicalClaimStatus.fromValue('unknown'),
        MedicalClaimStatus.submitted,
      );
    });
  });

  group('Models serialization & helpers', () {
    test('MedicalClaim round-trips through toMap and fromMap', () {
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
            documentType: 'Medical bill',
            fileName: 'ent-bill.jpg',
            storagePath: 'medical_claims/MED-2026-999/ent-bill.jpg',
            downloadUrl: 'https://example.com/ent-bill.jpg',
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

      final restored = MedicalClaim.fromMap(original.toMap());

      expect(restored.claimId, original.claimId);
      expect(restored.userId, original.userId);
      expect(restored.policyId, original.policyId);
      expect(restored.claimType, 'Medical');
      expect(restored.claimAmount, 65400.50);
      expect(restored.status, MedicalClaimStatus.underReview);
      expect(restored.patientName, 'Nimal Silva');
      expect(restored.patientRelationship, 'Self');
      expect(restored.hospitalName, 'Durdans Hospital');
      expect(restored.treatmentType, 'Outpatient');
      expect(restored.billNumber, 'DRD-10293');
      expect(restored.documents.length, 1);
      expect(restored.documents.first.fileName, 'ent-bill.jpg');
    });

    test('OcrBillData parses map and reports field presence', () {
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
      expect(ocr.hospitalName, 'Asiri Hospital');
      expect(ocr.billDate, DateTime(2026, 11, 21));
    });

    test('formatLkr formats Sri Lankan Rupee amounts cleanly', () {
      expect(formatLkr(0), 'LKR 0.00');
      expect(formatLkr(24750), 'LKR 24,750.00');
      expect(formatLkr(185500.5), 'LKR 185,500.50');
      expect(formatLkr(1250000), 'LKR 1,250,000.00');
    });
  });

  group('MedicalClaimService & InMemoryMedicalClaimRepository', () {
    late InMemoryMedicalClaimRepository repository;
    late MedicalClaimService service;

    setUp(() async {
      repository = InMemoryMedicalClaimRepository(
        simulatedDelay: Duration.zero,
      );
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

    test('loads 3 seeded Sri Lankan claims sorted newest first', () {
      expect(service.claims.length, 3);
      expect(service.claims.first.hospitalName, 'Lanka Hospitals');
      expect(service.countByStatus(MedicalClaimStatus.submitted), 1);
      expect(service.countByStatus(MedicalClaimStatus.underReview), 1);
      expect(service.countByStatus(MedicalClaimStatus.approved), 1);
      expect(service.totalClaimedAmount, 252550.00);
      expect(service.approvedAmount, 24750.00);
    });

    test('filters claims by status and search query', () {
      service.setStatusFilter(MedicalClaimStatus.approved);
      expect(service.filteredClaims.length, 1);
      expect(service.filteredClaims.first.hospitalName, 'Nawaloka Hospital');

      service.setStatusFilter(null);
      service.setSearchQuery('asiri');
      expect(service.filteredClaims.length, 1);
      expect(service.filteredClaims.first.claimId, 'MED-2026-001');

      service.setSearchQuery('ASH-2026-88412');
      expect(service.filteredClaims.length, 1);
    });

    test('submitMedicalClaim persists claim with attached local bill', () async {
      final created = await service.submitMedicalClaim(
        userId: 'DEMO-USER-01',
        policyId: 'MEDICAL-001',
        claimAmount: 14500.00,
        description: 'Pharmacy prescription refill.',
        patientName: 'Kasun Perera',
        patientRelationship: 'Self',
        hospitalName: 'Hemas Hospital',
        treatmentType: 'Pharmacy',
        billNumber: 'HMS-2026-100',
        billDate: DateTime(2026, 11, 21),
        localBillFilePath: '/tmp/hemas-receipt.jpg',
      );

      expect(created, isNotNull);
      expect(created!.status, MedicalClaimStatus.submitted);
      expect(created.documents.length, 1);
      expect(created.documents.first.fileName, 'hemas-receipt.jpg');
      expect(service.claims.length, 4);

      final fetched = await service.getClaimById(created.claimId);
      expect(fetched?.hospitalName, 'Hemas Hospital');
    });
  });
}
