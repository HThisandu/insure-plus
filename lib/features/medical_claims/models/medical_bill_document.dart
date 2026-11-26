import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a pending local medical bill or medical report selected by the
/// user prior to uploading to the private `claim-documents` Supabase bucket.
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
    if (lower.endsWith('.webp')) return 'image/webp';
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

/// Matches the shared Firestore `claims.documents` item structure:
/// `documentId`, `documentType`, `fileName`, `storagePath`, `uploadedAt`.
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

  /// Local-only path used for in-memory preview/testing; never persisted to
  /// Firestore so the backend document schema stays strictly 5 fields.
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
    return MedicalBillDocument(
      documentId: (map['documentId'] as String?) ?? '',
      documentType: (map['documentType'] as String?) ?? 'Medical Bill',
      fileName: (map['fileName'] as String?) ?? '',
      storagePath: (map['storagePath'] as String?) ?? '',
      uploadedAt: _parseDateTime(map['uploadedAt']) ?? DateTime.now(),
    );
  }

  MedicalBillDocument copyWith({
    String? documentId,
    String? documentType,
    String? fileName,
    String? storagePath,
    DateTime? uploadedAt,
    String? localPreviewPath,
  }) {
    return MedicalBillDocument(
      documentId: documentId ?? this.documentId,
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      storagePath: storagePath ?? this.storagePath,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      localPreviewPath: localPreviewPath ?? this.localPreviewPath,
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
        other.uploadedAt == uploadedAt;
  }

  @override
  int get hashCode =>
      Object.hash(documentId, documentType, fileName, storagePath, uploadedAt);
}
