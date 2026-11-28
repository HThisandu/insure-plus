import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insure_plus/features/medical_claims/medical_claims.dart';

Widget _buildTestApp(Widget home) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: MedicalClaimsColors.navy),
    ),
    home: home,
  );
}

void main() {
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

  group('MedicalClaimsHomeScreen (Figma UI)', () {
    testWidgets('renders Figma header, inline timeline, and filters claims', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(MedicalClaimsHomeScreen(service: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your claims, in view.'), findsOneWidget);
      expect(find.text('Submit a new claim'), findsOneWidget);
      expect(find.text('Lanka Hospitals'), findsOneWidget);

      // Filter by Closed (1) -> Nawaloka Hospital only
      final closedPill = find.text('Closed (1)');
      await tester.ensureVisible(closedPill);
      await tester.tap(closedPill);
      await tester.pumpAndSettle();

      expect(find.text('Nawaloka Hospital'), findsOneWidget);
      expect(find.text('Asiri Hospital'), findsNothing);

      // Filter by Under review (1) -> Asiri Hospital with inline timeline
      final underReviewPill = find.text('Under review (1)');
      await tester.ensureVisible(underReviewPill);
      await tester.tap(underReviewPill);
      await tester.pumpAndSettle();

      expect(find.text('Asiri Hospital'), findsOneWidget);
      expect(find.text('Our team is reviewing'), findsOneWidget);
    });
  });

  group('SubmitMedicalClaimScreen (Figma UI)', () {
    testWidgets('validates required fields and submits a new medical claim', (
      tester,
    ) async {
      MedicalClaim? returnedClaim;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    returnedClaim = await Navigator.of(context)
                        .push<MedicalClaim>(
                          MaterialPageRoute(
                            builder: (_) => SubmitMedicalClaimScreen(
                              service: service,
                              userId: 'DEMO-USER-01',
                            ),
                          ),
                        );
                  },
                  child: const Text('Open Form'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();

      expect(find.text('Let\'s get you covered.'), findsOneWidget);
      expect(find.text('Here when you need us.'), findsOneWidget);
      expect(find.text('Supporting documents'), findsOneWidget);

      final submitBtn = find.text('Submit claim');
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Patient name is required'), findsOneWidget);
      expect(find.text('Hospital name is required'), findsOneWidget);
      expect(find.text('Claim amount is required'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Patient Name'),
        'Amaya Fernando',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Hospital Name'),
        'Hemas Hospital',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Claim Amount'),
        '18500.00',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description / Notes'),
        'Outpatient specialist consultation and diagnostic blood tests.',
      );

      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(returnedClaim, isNotNull);
      expect(returnedClaim!.patientName, 'Amaya Fernando');
      expect(returnedClaim!.hospitalName, 'Hemas Hospital');
      expect(returnedClaim!.claimAmount, 18500.00);
      expect(service.claims.length, 4);
    });

    testWidgets(
      'prefills OCR bill data, warns on excess balance, and submits cleanly',
      (tester) async {
        final ocrPrefill = OcrBillData(
          hospitalName: 'Durdans Hospital',
          billNumber: 'DRD-2026-55018',
          billDate: DateTime(2026, 11, 21),
          amount: 275000.00,
          localImagePath: '/tmp/durdans-invoice.jpg',
        );

        await tester.pumpWidget(
          _buildTestApp(
            SubmitMedicalClaimScreen(
              service: service,
              userId: 'DEMO-USER-01',
              initialPolicyId: 'MEDICAL-001',
              ocrPrefill: ocrPrefill,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Auto-filled from AI Bill OCR — please verify details'),
          findsOneWidget,
        );
        expect(find.text('DRD-2026-55018'), findsOneWidget);
        expect(find.text('275000.00'), findsOneWidget);
        expect(find.text('durdans-invoice.jpg'), findsOneWidget);
        expect(
          find.textContaining('exceeds your remaining balance'),
          findsOneWidget,
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Patient Name'),
          'Kasun Perera',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Description / Notes'),
          'Inpatient cardiac procedure verified via OCR invoice.',
        );

        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        final submitBtn = find.byIcon(Icons.chevron_right_rounded).last;
        await tester.scrollUntilVisible(
          submitBtn,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(submitBtn);
        await tester.pumpAndSettle();
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        final saved = service.claims.firstWhere(
          (c) => c.billNumber == 'DRD-2026-55018',
        );
        expect(saved.hospitalName, 'Durdans Hospital');
        expect(saved.documents.single.fileName, 'durdans-invoice.jpg');
      },
    );
  });

  group('MedicalClaimDetailsScreen (Figma UI)', () {
    testWidgets(
      'displays navy hero card, timeline, patient info, and Supabase documents',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            MedicalClaimDetailsScreen(
              service: service,
              claimId: 'MED-2026-001',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Medical Claim Details'), findsOneWidget);
        expect(find.text('MED-2026-001'), findsOneWidget);
        expect(find.text('LKR 185,500.00'), findsOneWidget);
        expect(find.text('Claim Progress'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Kasun Perera'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Kasun Perera'), findsOneWidget);
        expect(find.text('Asiri Hospital'), findsWidgets);

        await tester.scrollUntilVisible(
          find.text('asiri-surgical-final-bill.pdf'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('ASH-2026-88412'), findsOneWidget);
        expect(find.text('asiri-surgical-final-bill.pdf'), findsOneWidget);
      },
    );
  });

  group('Orientation & Configuration Change Resilience', () {
    Future<void> verifyPortraitAndLandscape(
      WidgetTester tester,
      Widget screen,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
      tester.view.devicePixelRatio = 1.0;

      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(_buildTestApp(screen));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpWidget(_buildTestApp(screen));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    testWidgets(
      'MedicalClaimsHomeScreen handles portrait and landscape without overflow',
      (tester) async {
        await verifyPortraitAndLandscape(
          tester,
          MedicalClaimsHomeScreen(service: service),
        );
      },
    );

    testWidgets(
      'SubmitMedicalClaimScreen handles portrait and landscape without overflow',
      (tester) async {
        await verifyPortraitAndLandscape(
          tester,
          SubmitMedicalClaimScreen(
            service: service,
            userId: 'DEMO-USER-01',
            ocrPrefill: OcrBillData(
              hospitalName: 'Asiri Hospital',
              billNumber: 'ASH-2026-10001',
              billDate: DateTime(2026, 11, 20),
              amount: 260000.00,
              localImagePath: '/tmp/sample-bill.jpg',
            ),
          ),
        );
      },
    );

    testWidgets(
      'MedicalClaimDetailsScreen handles portrait and landscape without overflow',
      (tester) async {
        await verifyPortraitAndLandscape(
          tester,
          MedicalClaimDetailsScreen(
            service: service,
            claimId: 'MED-2026-001',
          ),
        );
      },
    );
  });
}
