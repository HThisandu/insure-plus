import 'package:flutter_test/flutter_test.dart';
import 'package:insure_plus/features/ocr/services/ocr_bill_parser.dart';

void main() {
  group('OcrBillParser Tests', () {
    test('extracts hospital, bill number, date, and amount correctly', () {
      const rawSample = '''
      ASIRI SURGICAL HOSPITAL
      21 Kirimandala Mawatha, Colombo 05
      
      INVOICE NO: INV-2026-88341
      DATE: 2026-11-20
      
      Patient: John Doe
      Consultation Fee: LKR 3,500.00
      Pharmacy charges: LKR 12,000.00
      Lab investigation: LKR 6,250.00
      
      GRAND TOTAL: LKR 21,750.00
      THANK YOU FOR CHOOSING ASIRI
      ''';

      final result = OcrBillParser.parseText(rawSample);

      expect(result.hospitalName, equals('Asiri Surgical'));
      expect(result.billNumber, equals('INV-2026-88341'));
      expect(result.billDate, equals(DateTime(2026, 11, 20)));
      expect(result.amount, equals(21750.00));
      expect(result.rawText, equals(rawSample));
    });

    test('parses Durdans bill with text date and Net Total format', () {
      const rawSample = '''
      Durdans Hospital
      Receipt No: DRD-99812
      Bill Date: 15/10/2026
      
      Total Payable: Rs. 48,500.50
      ''';

      final result = OcrBillParser.parseText(rawSample);

      expect(result.hospitalName, equals('Durdans Hospital'));
      expect(result.billNumber, equals('DRD-99812'));
      expect(result.billDate, equals(DateTime(2026, 10, 15)));
      expect(result.amount, equals(48500.50));
    });

    test('handles empty or unrecognized text gracefully', () {
      final result = OcrBillParser.parseText('');

      expect(result.hospitalName, isNull);
      expect(result.billNumber, isNull);
      expect(result.billDate, isNull);
      expect(result.amount, isNull);
    });

    test('parses textual date format like 24 Nov 2026', () {
      const rawSample = '''
      Nawaloka Hospital PLC
      Ref: BILL-77123
      Date: 24 Nov 2026
      Net Amount: LKR 15,000.00
      ''';

      final result = OcrBillParser.parseText(rawSample);

      expect(result.hospitalName, equals('Nawaloka Hospital'));
      expect(result.billNumber, equals('BILL-77123'));
      expect(result.billDate, equals(DateTime(2026, 11, 24)));
      expect(result.amount, equals(15000.00));
    });
  });
}
