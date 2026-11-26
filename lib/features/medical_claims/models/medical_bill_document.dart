import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalBillDocument {
  const MedicalBillDocument({
    required this.documentId,
    required this.documentType,
    required this.fileName,
    required this.storagePath,
    this.downloadUrl,
    required this.uploadedAt,
  });

  final String documentId;
  final String documentType;
  final String fileName;
  final String storagePath;
  final String? downloadUrl;
  final DateTime uploadedAt;

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'documentType': documentType,
      'fileName': fileName,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory MedicalBillDocument.fromMap(Map<String, dynamic> map) {
    return MedicalBillDocument(
      documentId: (map['documentId'] as String?) ?? '',
      documentType: (map['documentType'] as String?) ?? 'Medical bill',
      fileName: (map['fileName'] as String?) ?? '',
      storagePath: (map['storagePath'] as String?) ?? '',
      downloadUrl: map['downloadUrl'] as String?,
      uploadedAt: _parseDateTime(map['uploadedAt']) ?? DateTime.now(),
    );
  }

  MedicalBillDocument copyWith({
    String? documentId,
    String? documentType,
    String? fileName,
    String? storagePath,
    String? downloadUrl,
    DateTime? uploadedAt,
  }) {
    return MedicalBillDocument(
      documentId: documentId ?? this.documentId,
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      storagePath: storagePath ?? this.storagePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MedicalBillDocument &&
        other.documentId == documentId &&
        other.documentType == documentType &&
        other.fileName == fileName &&
        other.storagePath == storagePath &&
        other.downloadUrl == downloadUrl &&
        other.uploadedAt == uploadedAt;
  }

  @override
  int get hashCode => Object.hash(
    documentId,
    documentType,
    fileName,
    storagePath,
    downloadUrl,
    uploadedAt,
  );
}
