class ClaimDocument {
  const ClaimDocument({
    required this.documentId,
    required this.documentType,
    required this.fileName,
    required this.storagePath,
    required this.uploadedAt,
  });

  final String documentId;
  final String documentType;
  final String fileName;
  final String storagePath;
  final DateTime uploadedAt;
}
