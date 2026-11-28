import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes Supabase and forwards the signed-in Firebase ID token.
///
/// Firebase remains the identity provider. Supabase uses that verified token
/// for PostgreSQL Row Level Security and private Storage access.
class SupabaseAppService {
  SupabaseAppService._();

  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool _initialized = false;

  static bool get isConfigured =>
      _url.startsWith('https://') && _publishableKey.isNotEmpty;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!isConfigured) {
      debugPrint(
        'Supabase is not configured. Add SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY using --dart-define-from-file.',
      );
      return;
    }

    await Supabase.initialize(
      url: _url,
      publishableKey: _publishableKey,
      accessToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
        return user.getIdToken();
      },
    );

    _initialized = true;
    debugPrint('Supabase initialized with Firebase Authentication tokens.');
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'Supabase is not configured. Create supabase_config.json from '
        'supabase_config.json.example and restart the app.',
      );
    }
    return Supabase.instance.client;
  }
}
