import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insure_plus/features/medical_claims/models/ocr_bill_data.dart';
import 'package:insure_plus/features/ocr/screens/ocr_bill_review_screen.dart';

void main() {
  group('OcrBillReviewScreen Widget Tests', () {
    testWidgets('displays extracted fields and allows user correction',
        (tester) async {
      final initialData = OcrBillData(
        hospitalName: 'Asiri Hospital',
        billNumber: 'INV-1001',
        billDate: DateTime(2026, 11, 20),
        amount: 25000.00,
        rawText: 'Raw OCR Content from medical bill',
      );

      OcrBillData? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    submittedData = await Navigator.of(context).push<OcrBillData>(
                      MaterialPageRoute(
                        builder: (_) => OcrBillReviewScreen(
                          initialData: initialData,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Review'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open screen
      await tester.tap(find.text('Open Review'));
      await tester.pumpAndSettle();

      // Verify fields pre-populated
      expect(find.text('Review Extracted Bill'), findsOneWidget);
      expect(find.text('Asiri Hospital'), findsOneWidget);
      expect(find.text('INV-1001'), findsOneWidget);
      expect(find.text('25000.00'), findsOneWidget);
      expect(find.text('2026-11-20'), findsOneWidget);

      // Edit hospital name and amount
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Asiri Hospital'),
        'Lanka Hospitals',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '25000.00'),
        '30000.00',
      );
      await tester.pumpAndSettle();

      // Tap 'Apply to Claim'
      await tester.tap(find.text('Apply to Claim'));
      await tester.pumpAndSettle();

      // Verify returned data reflects user edits
      expect(submittedData, isNotNull);
      expect(submittedData!.hospitalName, equals('Lanka Hospitals'));
      expect(submittedData!.billNumber, equals('INV-1001'));
      expect(submittedData!.amount, equals(30000.00));
      expect(submittedData!.billDate, equals(DateTime(2026, 11, 20)));
    });

    testWidgets('validates required fields on submission', (tester) async {
      const emptyData = OcrBillData();

      await tester.pumpWidget(
        const MaterialApp(
          home: OcrBillReviewScreen(initialData: emptyData),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Apply without entering fields
      await tester.tap(find.text('Apply to Claim'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter hospital name'), findsOneWidget);
      expect(find.text('Please enter bill number'), findsOneWidget);
      expect(find.text('Please enter total amount'), findsOneWidget);
    });
  });
}
