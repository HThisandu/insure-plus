/// Data transfer object used by Member 06's Google ML Kit OCR module to pass
/// extracted and user-verified medical bill fields into the Medical Claims
/// submission flow.
class OcrBillData {
  const OcrBillData({
    this.billNumber,
    this.billDate,
    this.amount,
    this.hospitalName,
    this.localImagePath,
    this.rawText,
  });

  final String? billNumber;
  final DateTime? billDate;
  final double? amount;
  final String? hospitalName;
  final String? localImagePath;
  final String? rawText;

  bool get hasExtractedFields =>
      (billNumber != null && billNumber!.trim().isNotEmpty) ||
      billDate != null ||
      amount != null ||
      (hospitalName != null && hospitalName!.trim().isNotEmpty);

  bool get hasImage =>
      localImagePath != null && localImagePath!.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'billNumber': billNumber,
      'billDate': billDate?.toIso8601String(),
      'amount': amount,
      'hospitalName': hospitalName,
      'localImagePath': localImagePath,
      'rawText': rawText,
    };
  }

  factory OcrBillData.fromMap(Map<String, dynamic> map) {
    final rawDate = map['billDate'];
    DateTime? parsedDate;
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    final rawAmount = map['amount'];
    double? parsedAmount;
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount.replaceAll(',', '').trim());
    }

    return OcrBillData(
      billNumber: map['billNumber'] as String?,
      billDate: parsedDate,
      amount: parsedAmount,
      hospitalName: map['hospitalName'] as String?,
      localImagePath: map['localImagePath'] as String?,
      rawText: map['rawText'] as String?,
    );
  }

  OcrBillData copyWith({
    String? billNumber,
    DateTime? billDate,
    double? amount,
    String? hospitalName,
    String? localImagePath,
    String? rawText,
  }) {
    return OcrBillData(
      billNumber: billNumber ?? this.billNumber,
      billDate: billDate ?? this.billDate,
      amount: amount ?? this.amount,
      hospitalName: hospitalName ?? this.hospitalName,
      localImagePath: localImagePath ?? this.localImagePath,
      rawText: rawText ?? this.rawText,
    );
  }
}
