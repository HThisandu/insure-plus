import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase_config.dart';

class SupabaseAppService {
  SupabaseAppService._();

  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static String get _url =>
      _envUrl.isNotEmpty ? _envUrl : SupabaseConfig.supabaseUrl;

  static String get _publishableKey =>
      _envKey.isNotEmpty ? _envKey : SupabaseConfig.supabasePublishableKey;

  static bool _initialized = false;

  static bool get isConfigured =>
      _url.startsWith('https://') && _publishableKey.isNotEmpty;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (!isConfigured) {
      debugPrint('Supabase is not configured.');
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
  }

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase is not initialized.');
    }
    return Supabase.instance.client;
  }
}
