
/// Represents a supporting document or photo attached to an insurance claim in Insure-Plus.
///
/// Contains the exact required fields:
/// - [documentId]: Unique identifier for the document
/// - [documentType]: Type of document (e.g. 'AccidentPhoto', 'PoliceReport', 'DrivingLicense', 'RepairEstimate')
/// - [fileName]: Original name of the file
/// - [fileUrl]: Private Supabase Storage object path
/// - [uploadedAt]: Timestamp of upload
class ClaimDocument {
  final String documentId;
  final String documentType;
  final String fileName;
  final String fileUrl;
  final DateTime uploadedAt;

  ClaimDocument({
    required this.documentId,
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  /// Converts this document to a Map for Firestore persistence.
  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'documentType': documentType,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'uploadedAt': uploadedAt,
    };
  }

  /// Deserializes a document from a Map (e.g. from Firestore).
  factory ClaimDocument.fromMap(Map<String, dynamic> map) {
    return ClaimDocument(
      documentId: map['documentId'] as String? ?? '',
      documentType: map['documentType'] as String? ?? 'General',
      fileName: map['fileName'] as String? ?? '',
      fileUrl: map['fileUrl'] as String? ?? '',
      uploadedAt: _readUploadedAt(map['uploadedAt']),
    );
  }

  /// Helper to create a copy of the document with optional updated fields.
  ClaimDocument copyWith({
    String? documentId,
    String? documentType,
    String? fileName,
    String? fileUrl,
    DateTime? uploadedAt,
  }) {
    return ClaimDocument(
      documentId: documentId ?? this.documentId,
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}

DateTime _readUploadedAt(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
