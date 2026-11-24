import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../common/models/claim_document.dart';
import '../../../common/services/supabase_app_service.dart';

/// Private Supabase Storage access for Motor Claims documents and photos.
class MotorClaimStorageService {
  MotorClaimStorageService._();

  static final MotorClaimStorageService instance =
      MotorClaimStorageService._();

  static const String bucketName = 'claim-documents';

  SupabaseStorageClient get _storage => SupabaseAppService.client.storage;

  Future<ClaimDocument> uploadClaimFile({
    required String userId,
    required String claimId,
    required PlatformFile file,
    required String documentType,
  }) async {
    if (userId.isEmpty || claimId.isEmpty) {
      throw ArgumentError('A signed-in user and claim ID are required.');
    }
    if (documentType != 'AccidentPhoto' &&
        documentType != 'SupportingDocument') {
      throw ArgumentError.value(documentType, 'documentType');
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError('Could not read ${file.name}. Please select it again.');
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw StateError('${file.name} is larger than the 10 MB upload limit.');
    }

    final contentType = _contentTypeFor(file.name, documentType);
    final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final documentId = 'DOC-${DateTime.now().microsecondsSinceEpoch}';
    final objectPath =
        '$userId/$claimId/$documentType/$documentId-$safeName';

    await _storage.from(bucketName).uploadBinary(
      objectPath,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        cacheControl: '3600',
        upsert: false,
      ),
    );

    return ClaimDocument(
      documentId: documentId,
      documentType: documentType,
      fileName: file.name,
      // Store the private object path, not a public or permanent URL.
      fileUrl: objectPath,
      uploadedAt: DateTime.now(),
    );
  }

  Future<String> createDownloadUrl(String objectPath) async {
    if (objectPath.isEmpty) {
      throw ArgumentError.value(objectPath, 'objectPath');
    }

    return _storage
        .from(bucketName)
        .createSignedUrl(objectPath, 60 * 60);
  }

  Future<void> deleteClaimFile(String objectPath) async {
    if (objectPath.isEmpty) return;
    await _storage.from(bucketName).remove([objectPath]);
  }

  String _contentTypeFor(String fileName, String documentType) {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        if (documentType == 'AccidentPhoto') return 'image/webp';
        break;
      case 'pdf':
        if (documentType == 'SupportingDocument') return 'application/pdf';
        break;
      case 'doc':
        if (documentType == 'SupportingDocument') return 'application/msword';
        break;
      case 'docx':
        if (documentType == 'SupportingDocument') {
          return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        }
        break;
    }

    throw StateError('Unsupported file type: .$extension');
  }
}
