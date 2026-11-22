import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insure_plus/features/medical_claims/medical_claims.dart';

Widget _wrapWithTheme(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF175E59)),
    ),
    home: child,
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

  group('MedicalClaimsHomeScreen', () {
    testWidgets('displays seeded claims, filters by status, and opens details', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithTheme(MedicalClaimsHomeScreen(service: service)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Medical Claims'), findsOneWidget);
      expect(find.text('Lanka Hospitals'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Nawaloka Hospital'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Nawaloka Hospital'), findsOneWidget);

      final approvedChip = find.text('Approved (1)');
      await tester.ensureVisible(approvedChip);
      await tester.tap(approvedChip);
      await tester.pumpAndSettle();

      expect(find.text('Nawaloka Hospital'), findsOneWidget);
      expect(find.text('Asiri Hospital'), findsNothing);

      await tester.tap(find.text('Nawaloka Hospital'));
      await tester.pumpAndSettle();

      expect(find.text('Medical Claim Details'), findsOneWidget);
      expect(find.text('Claim Progress'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('nawaloka-opd-receipt.jpg'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('nawaloka-opd-receipt.jpg'), findsOneWidget);
    });

    testWidgets('renders cleanly in both portrait and landscape orientations', (
      tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(
        _wrapWithTheme(MedicalClaimsHomeScreen(service: service)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpWidget(
        _wrapWithTheme(MedicalClaimsHomeScreen(service: service)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('SubmitMedicalClaimScreen', () {
    testWidgets('prefills OCR fields and warns when exceeding policy balance', (
      tester,
    ) async {
      final ocr = OcrBillData(
        hospitalName: 'Durdans Hospital',
        billNumber: 'DRD-2026-55018',
        billDate: DateTime(2026, 11, 21),
        amount: 310000.00,
        localImagePath: '/tmp/durdans-bill.jpg',
      );

      await tester.pumpWidget(
        _wrapWithTheme(
          SubmitMedicalClaimScreen(
            service: service,
            userId: 'DEMO-USER-01',
            initialPolicyId: 'MEDICAL-001',
            ocrPrefill: ocr,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Auto-filled from AI Bill OCR — please verify details'),
        findsOneWidget,
      );
      expect(find.text('Durdans Hospital'), findsWidgets);
      expect(find.text('DRD-2026-55018'), findsOneWidget);
      expect(find.text('310000.00'), findsOneWidget);
      expect(
        find.textContaining('exceeds your remaining balance'),
        findsOneWidget,
      );
      expect(find.text('durdans-bill.jpg'), findsOneWidget);
    });

    testWidgets('shows fallback snackbar when OCR button is not connected', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          SubmitMedicalClaimScreen(
            service: service,
            userId: 'DEMO-USER-01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ocrButton = find.text('Scan Bill with AI OCR');
      await tester.scrollUntilVisible(
        ocrButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(ocrButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Member 06'), findsOneWidget);
    });

    testWidgets('validates required inputs and submits a valid claim', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          SubmitMedicalClaimScreen(
            service: service,
            userId: 'DEMO-USER-01',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final submitButton = find.byIcon(Icons.send_outlined);
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Patient name is required'), findsOneWidget);

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
        '18500',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description / Notes'),
        'Outpatient specialist review and blood tests.',
      );

      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(service.claims.length, 4);
      expect(
        service.claims.any((claim) => claim.patientName == 'Amaya Fernando'),
        isTrue,
      );
    });

    testWidgets('renders form cleanly in landscape orientation', (
      tester,
    ) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpWidget(
        _wrapWithTheme(
          SubmitMedicalClaimScreen(
            service: service,
            userId: 'DEMO-USER-01',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
