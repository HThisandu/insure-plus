import 'package:intl/intl.dart';
import '../../medical_claims/models/ocr_bill_data.dart';

/// Pure Dart heuristic parser to extract structured medical bill fields
/// (Hospital Name, Bill/Invoice Number, Bill Date, Total Amount) from raw OCR text.
class OcrBillParser {
  const OcrBillParser();

  static const List<String> commonHospitals = [
    'Asiri Hospital',
    'Asiri Central Hospital',
    'Asiri Medical',
    'Asiri Surgical',
    'Nawaloka Hospital',
    'Lanka Hospitals',
    'Durdans Hospital',
    'Hemas Hospital',
    'Kings Hospital',
    'Golden Key Hospital',
    'Ninewells Hospital',
    'Medihelp Hospital',
    'Pannipitiya Private Hospital',
    'Ruhunu Hospital',
  ];

  /// Parses the raw OCR recognized text and extracts medical bill fields.
  static OcrBillData parseText(String rawText, {String? imagePath}) {
    if (rawText.trim().isEmpty) {
      return OcrBillData(
        localImagePath: imagePath,
        rawText: rawText,
      );
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final hospitalName = _extractHospital(lines);
    final billNumber = _extractBillNumber(lines);
    final billDate = _extractBillDate(lines);
    final amount = _extractTotalAmount(lines);

    return OcrBillData(
      billNumber: billNumber,
      billDate: billDate,
      amount: amount,
      hospitalName: hospitalName,
      localImagePath: imagePath,
      rawText: rawText,
    );
  }

  static String? _extractHospital(List<String> lines) {
    // 1. Look for known hospital names
    for (final line in lines.take(15)) {
      final normalized = line.toLowerCase();
      for (final hospital in commonHospitals) {
        if (normalized.contains(hospital.toLowerCase())) {
          return hospital;
        }
      }
    }

    // 2. Look for lines with hospital keywords
    final hospitalKeywords = RegExp(
      r'(hospital|clinic|medical center|healthcare|pharmacy|laborator(?:y|ies))',
      caseSensitive: false,
    );
    for (final line in lines.take(10)) {
      if (hospitalKeywords.hasMatch(line) && line.length < 50) {
        return line;
      }
    }

    // Fallback: the topmost non-numeric title line if available
    for (final line in lines.take(3)) {
      if (line.length >= 4 &&
          line.length <= 40 &&
          !RegExp(r'\d{3,}').hasMatch(line)) {
        return line;
      }
    }

    return null;
  }

  static String? _extractBillNumber(List<String> lines) {
    final billPatterns = [
      // e.g. Bill No: INV-10293, Invoice #: 99283, Receipt No: RC/2026/01
      RegExp(r'(?:bill\s*(?:no|#|num)?|invoice\s*(?:no|#|num)?|receipt\s*(?:no|#)?|ref\s*(?:no|#)?)\s*[:.\-]?\s*([A-Za-z0-9\-\/]{3,25})', caseSensitive: false),
      // e.g. INV/2026/00123 or BILL-9921
      RegExp(r'\b(INV[-/][A-Za-z0-9\-_]{3,20})\b', caseSensitive: false),
      RegExp(r'\b(BILL[-/][A-Za-z0-9\-_]{3,20})\b', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in billPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final candidate = match.group(1)?.trim();
          if (candidate != null &&
              candidate.isNotEmpty &&
              !candidate.toLowerCase().contains('date') &&
              !candidate.toLowerCase().contains('time')) {
            return candidate;
          }
        }
      }
    }

    return null;
  }

  static DateTime? _extractBillDate(List<String> lines) {
    // Match date patterns like 2026-11-20, 20/11/2026, 20.11.2026, 20 Nov 2026
    final datePrefixPattern = RegExp(
      r'(?:date|invoice\s*date|bill\s*date|dated)\s*[:.\-]?\s*([A-Za-z0-9\-\/\.\s]{6,20})',
      caseSensitive: false,
    );

    for (final line in lines) {
      final prefixMatch = datePrefixPattern.firstMatch(line);
      if (prefixMatch != null) {
        final dateStr = prefixMatch.group(1)?.trim();
        if (dateStr != null) {
          final parsed = _parseDateString(dateStr);
          if (parsed != null) return parsed;
        }
      }
    }

    // Direct search for date shapes in lines
    for (final line in lines) {
      final parsed = _parseDateString(line);
      if (parsed != null) return parsed;
    }

    return null;
  }

  static DateTime? _parseDateString(String input) {
    // 1. YYYY-MM-DD or YYYY/MM/DD
    final ymdMatch = RegExp(r'\b(20\d\d)[-/.](0?[1-9]|1[0-2])[-/.](0?[1-9]|[12]\d|3[01])\b')
        .firstMatch(input);
    if (ymdMatch != null) {
      try {
        final year = int.parse(ymdMatch.group(1)!);
        final month = int.parse(ymdMatch.group(2)!);
        final day = int.parse(ymdMatch.group(3)!);
        return DateTime(year, month, day);
      } catch (_) {}
    }

    // 2. DD-MM-YYYY or DD/MM/YYYY
    final dmyMatch = RegExp(r'\b(0?[1-9]|[12]\d|3[01])[-/.](0?[1-9]|1[0-2])[-/.](20\d\d)\b')
        .firstMatch(input);
    if (dmyMatch != null) {
      try {
        final day = int.parse(dmyMatch.group(1)!);
        final month = int.parse(dmyMatch.group(2)!);
        final year = int.parse(dmyMatch.group(3)!);
        return DateTime(year, month, day);
      } catch (_) {}
    }

    // 3. DD MMM YYYY (e.g. 24 Nov 2026)
    final textDateMatch = RegExp(
      r'\b(0?[1-9]|[12]\d|3[01])\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(20\d\d)\b',
      caseSensitive: false,
    ).firstMatch(input);
    if (textDateMatch != null) {
      try {
        final format = DateFormat('d MMM yyyy');
        return format.parse(
          '${textDateMatch.group(1)} ${textDateMatch.group(2)} ${textDateMatch.group(3)}',
        );
      } catch (_) {}
    }

    return null;
  }

  static double? _extractTotalAmount(List<String> lines) {
    // Patterns that explicitly declare total amount
    final explicitTotalPattern = RegExp(
      r'(?:total\s*amount|grand\s*total|net\s*total|net\s*amount|total\s*payable|amount\s*due|balance\s*due|total)\s*[:.\-]?\s*(?:lkr|rs\.?|slr)?\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );

    // Look backwards from bottom of bill (where totals normally sit)
    for (final line in lines.reversed) {
      final match = explicitTotalPattern.firstMatch(line);
      if (match != null) {
        final numStr = match.group(1)?.replaceAll(',', '').trim();
        final parsed = double.tryParse(numStr ?? '');
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    }

    // Secondary scan: currency prefix (LKR / Rs. 15,000.00)
    final currencyPattern = RegExp(
      r'(?:lkr|rs\.?)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{1,2})?|[0-9]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    );
    double highestCurrencyAmount = 0.0;
    for (final line in lines) {
      final match = currencyPattern.firstMatch(line);
      if (match != null) {
        final numStr = match.group(1)?.replaceAll(',', '').trim();
        final parsed = double.tryParse(numStr ?? '');
        if (parsed != null && parsed > highestCurrencyAmount) {
          highestCurrencyAmount = parsed;
        }
      }
    }
    if (highestCurrencyAmount > 0) {
      return highestCurrencyAmount;
    }

    return null;
  }
}
