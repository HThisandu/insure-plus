import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Firebase provides authentication only in the hybrid architecture.
/// Claim records and private uploads are handled by Supabase.
class FirebaseAppService {
  FirebaseAppService._();

  static const String currentAppName = '[DEFAULT]';

  static FirebaseApp get currentApp => Firebase.app();

  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
