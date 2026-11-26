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
    DateTime? parsedDate;
    final rawDate = map['billDate'];
    if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    double? parsedAmount;
    final rawAmount = map['amount'];
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
}
