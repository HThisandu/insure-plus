import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Uint8List> downloadClaimDocument({required String storagePath}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final fileBytes = await _supabase.storage
        .from('claim-documents')
        .download(storagePath);

    return fileBytes;
  }

  Future<String> uploadClaimDocument({
    required String claimId,
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    final filePath =
        '${user.uid}/$claimId/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

    await _supabase.storage
        .from('claim-documents')
        .uploadBinary(
          filePath,
          fileBytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    return filePath;
  }

  Future<void> deleteClaimDocument({required String storagePath}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final fileOwnerUid = storagePath.split('/').first;

    if (fileOwnerUid != user.uid) {
      throw Exception('You cannot delete another user\'s file');
    }

    await _supabase.storage.from('claim-documents').remove([storagePath]);
  }
}
