import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

// Selected file before uploading to Supabase Storage
class PendingMedicalAttachment {
  const PendingMedicalAttachment({
    required this.fileName,
    this.documentType = 'Medical Bill',
    this.localPath,
    this.bytes,
    this.fileSizeBytes,
  });

  final String fileName;
  final String documentType;
  final String? localPath;
  final Uint8List? bytes;
  final int? fileSizeBytes;

  String get contentType {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  String get formattedSize {
    final size = fileSizeBytes ?? bytes?.length;
    if (size == null || size <= 0) return documentType;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class MedicalBillDocument {
  const MedicalBillDocument({
    required this.documentId,
    required this.documentType,
    required this.fileName,
    required this.storagePath,
    required this.uploadedAt,
    this.localPreviewPath,
  });

  final String documentId;
  final String documentType;
  final String fileName;
  final String storagePath;
  final DateTime uploadedAt;
  final String? localPreviewPath;

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'documentType': documentType,
      'fileName': fileName,
      'storagePath': storagePath,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory MedicalBillDocument.fromMap(Map<String, dynamic> map) {
    final rawDate = map['uploadedAt'];
    DateTime uploaded = DateTime.now();
    if (rawDate is Timestamp) {
      uploaded = rawDate.toDate();
    } else if (rawDate is DateTime) {
      uploaded = rawDate;
    } else if (rawDate is String) {
      uploaded = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    return MedicalBillDocument(
      documentId: (map['documentId'] as String?) ?? '',
      documentType: (map['documentType'] as String?) ?? 'Medical Bill',
      fileName: (map['fileName'] as String?) ?? '',
      storagePath: (map['storagePath'] as String?) ?? '',
      uploadedAt: uploaded,
    );
  }
}
