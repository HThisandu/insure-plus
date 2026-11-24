import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insure_plus/modules/motor_claims/motor_claims.dart';

void main() {
  group('Motor Claims - Shared Schema and Statuses Tests', () {
    test('Allowed statuses ONLY: Submitted, UnderReview, MoreInfoRequired, Approved, Rejected', () {
      expect(ClaimStatus.values.length, 5);
      expect(ClaimStatus.submitted.value, 'Submitted');
      expect(ClaimStatus.underReview.value, 'UnderReview');
      expect(ClaimStatus.moreInfoRequired.value, 'MoreInfoRequired');
      expect(ClaimStatus.approved.value, 'Approved');
      expect(ClaimStatus.rejected.value, 'Rejected');

      // Verify no other statuses like Settled exist in the enum
      final statusNames = ClaimStatus.values.map((s) => s.value).toList();
      expect(statusNames.contains('Settled'), false);

      expect(ClaimStatus.fromString('Submitted'), ClaimStatus.submitted);
      expect(ClaimStatus.fromString('UnderReview'), ClaimStatus.underReview);
      expect(ClaimStatus.fromString('MoreInfoRequired'), ClaimStatus.moreInfoRequired);
      expect(ClaimStatus.fromString('Approved'), ClaimStatus.approved);
      expect(ClaimStatus.fromString('Rejected'), ClaimStatus.rejected);
    });

    test('ClaimDocument contains documentId, documentType, fileName, fileUrl, uploadedAt', () {
      final now = DateTime(2026, 11, 20, 14, 0);
      final doc = ClaimDocument(
        documentId: 'DOC-101',
        documentType: 'AccidentPhoto',
        fileName: 'front_damage.jpg',
        fileUrl: 'gs://insure-plus.appspot.com/claims/front_damage.jpg',
        uploadedAt: now,
      );

      expect(doc.documentId, 'DOC-101');
      expect(doc.documentType, 'AccidentPhoto');
      expect(doc.fileName, 'front_damage.jpg');
      expect(doc.fileUrl, 'gs://insure-plus.appspot.com/claims/front_damage.jpg');
      expect(doc.uploadedAt, now);

      final map = doc.toMap();
      expect(map['documentId'], 'DOC-101');
      expect(map['documentType'], 'AccidentPhoto');
      expect(map['fileName'], 'front_damage.jpg');
      expect(map['fileUrl'], 'gs://insure-plus.appspot.com/claims/front_damage.jpg');
      expect(map['uploadedAt'], now);

      final fromMap = ClaimDocument.fromMap(map);
      expect(fromMap.documentId, doc.documentId);
      expect(fromMap.documentType, doc.documentType);
      expect(fromMap.fileName, doc.fileName);
      expect(fromMap.fileUrl, doc.fileUrl);
    });

    test('MotorClaim correctly stores shared fields and serializes to Map', () {
      final now = DateTime(2026, 11, 20, 10, 30);
      final testDoc = ClaimDocument(
        documentId: 'DOC-POL-01',
        documentType: 'PoliceReport',
        fileName: 'Police_Report.pdf',
        fileUrl: 'gs://insure-plus.appspot.com/claims/Police_Report.pdf',
        uploadedAt: now,
      );
      final photoDoc = ClaimDocument(
        documentId: 'DOC-PHOTO-01',
        documentType: 'AccidentPhoto',
        fileName: 'Front_Damage.jpg',
        fileUrl: 'gs://insure-plus.appspot.com/claims/Front_Damage.jpg',
        uploadedAt: now,
      );

      final claim = MotorClaim(
        claimId: 'CLM-TEST-001',
        userId: 'USR-12345',
        policyId: 'POL-TEST-88',
        claimType: 'Motor Claim',
        claimAmount: 1450.00,
        description: 'Rear collision at stop light with broken bumper.',
        status: ClaimStatus.submitted,
        documents: [testDoc, photoDoc],
        createdAt: now,
        claimantName: 'John Doe',
        contactNumber: '+1 555-0100',
        vehicleRegistrationNumber: 'TEST-1234',
        vehicleMake: 'Toyota',
        vehicleModel: 'Corolla',
        vehicleYear: 2021,
        vehicleType: 'Car',
        incidentDate: now,
        incidentTime: '10:30 AM',
        incidentLocation: 'Highway 1',
        incidentType: 'Collision',
        damageSeverity: 'Moderate',
        isVehicleDrivable: true,
        policeReportFiled: true,
        policeReportNumber: 'PR-123',
        driverName: 'John Doe',
        driverLicenseNumber: 'D998877',
      );

      // Verify Exact Shared Fields
      expect(claim.claimId, 'CLM-TEST-001');
      expect(claim.userId, 'USR-12345');
      expect(claim.policyId, 'POL-TEST-88');
      expect(claim.claimType, 'Motor Claim');
      expect(claim.claimAmount, 1450.00);
      expect(claim.description, 'Rear collision at stop light with broken bumper.');
      expect(claim.status, ClaimStatus.submitted);
      expect(claim.documents.length, 2);
      expect(claim.createdAt, now);

      // Verify helpers
      expect(claim.accidentPhotos.length, 1);
      expect(claim.supportingDocuments.length, 1);
      expect(claim.vehicleDisplayName, '2021 Toyota Corolla (TEST-1234)');

      // Test Map serialization for Firestore
      final map = claim.toMap();
      expect(map['claimId'], 'CLM-TEST-001');
      expect(map['userId'], 'USR-12345');
      expect(map['policyId'], 'POL-TEST-88');
      expect(map['claimType'], 'Motor Claim');
      expect(map['claimAmount'], 1450.00);
      expect(map['status'], 'Submitted');
      expect(map['documents'] is List, true);

      // Test deserialization from Map
      final deserialized = MotorClaim.fromMap(map);
      expect(deserialized.claimId, claim.claimId);
      expect(deserialized.userId, claim.userId);
      expect(deserialized.status, ClaimStatus.submitted);
      expect(deserialized.documents.length, 2);
    });
  });

  group('Motor Claims - Service State Tests', () {
    late MotorClaimService service;

    setUp(() {
      service = MotorClaimService();
      service.resetToDefaultData();
    });

    test("Does not inject fabricated sample claims into a real user's list", () {
      expect(service.claims, isEmpty);
    });

    test('Statistics include only the five agreed statuses', () {
      final stats = service.getStatistics();
      expect(stats['total'], 0);
      expect(stats['submitted'], 0);
      expect(stats['underReview'], 0);
      expect(stats['moreInfoRequired'], 0);
      expect(stats['approved'], 0);
      expect(stats['rejected'], 0);
      expect(stats.containsKey('settled'), false);
    });

    test('Filtering an empty claims list returns no results', () {
      expect(service.getFilteredClaims(), isEmpty);
      expect(service.getFilteredClaims(status: ClaimStatus.approved), isEmpty);
    });
  });

  group('Motor Claims - Widgets Tests', () {
    testWidgets('ClaimStatusBadge displays all allowed status labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ClaimStatusBadge(status: ClaimStatus.submitted),
                ClaimStatusBadge(status: ClaimStatus.underReview),
                ClaimStatusBadge(status: ClaimStatus.moreInfoRequired),
                ClaimStatusBadge(status: ClaimStatus.approved),
                ClaimStatusBadge(status: ClaimStatus.rejected),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('More Info Required'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
    });

    testWidgets('AccidentPhotoUploadWidget renders uploaded photos', (WidgetTester tester) async {
      final photos = [
        ClaimDocument(
          documentId: 'PHOTO-01',
          documentType: 'AccidentPhoto',
          fileName: 'Front_Bumper_Damage.jpg',
          fileUrl: 'url1',
        ),
        ClaimDocument(
          documentId: 'PHOTO-02',
          documentType: 'AccidentPhoto',
          fileName: 'Windshield_Glass_Crack.jpg',
          fileUrl: 'url2',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AccidentPhotoUploadWidget(
                photos: photos,
                isReadOnly: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Accident Photos (2)'), findsOneWidget);
      expect(find.text('Front Bumper Damage'), findsOneWidget);
      expect(find.text('Windshield Glass Crack'), findsOneWidget);
    });

    testWidgets('MotorClaimCard renders claim details properly', (WidgetTester tester) async {
      final claim = MotorClaim(
        claimId: 'CLM-TEST-CARD',
        userId: 'USR-1',
        policyId: 'POL-1',
        claimAmount: 900.0,
        description: 'Test claim',
        claimantName: 'Alice',
        contactNumber: '+1 555-1111',
        vehicleRegistrationNumber: 'CARD-11',
        vehicleMake: 'Honda',
        vehicleModel: 'Civic',
        vehicleYear: 2022,
        incidentDate: DateTime(2026, 11, 10),
        incidentTime: '11:00 AM',
        incidentLocation: 'Street A',
        incidentType: 'Collision',
        driverName: 'Alice',
        driverLicenseNumber: 'D111',
        documents: [
          ClaimDocument(
            documentId: 'PHOTO-1',
            documentType: 'AccidentPhoto',
            fileName: 'Photo1.jpg',
            fileUrl: 'url',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MotorClaimCard(claim: claim),
          ),
        ),
      );

      expect(find.text('CLM-TEST-CARD'), findsOneWidget);
      expect(find.text('2022 Honda Civic'), findsOneWidget);
      expect(find.text('CARD-11'), findsOneWidget);
      expect(find.text('\$900.00'), findsOneWidget);
    });

    testWidgets('MotorClaimsDashboardScreen shows a retry message when Supabase is unavailable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MotorClaimsDashboardScreen(),
        ),
      );

      expect(find.text('Could not load claims from Supabase.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });
  });
}
