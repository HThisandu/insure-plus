import 'package:firebase_auth/firebase_auth.dart';

import '../../../common/services/firebase_app_service.dart';

/// Small wrapper around Firebase Authentication.
/// The app currently uses anonymous Firebase accounts until a full sign-in
/// screen is added. Each anonymous account still has a real Firebase UID.
class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  FirebaseAuth get _auth =>
      FirebaseAuth.instanceFor(app: FirebaseAppService.currentApp);

  User? get currentUser => _auth.currentUser;

  Future<User> ensureSignedIn() async {
    final existingUser = _auth.currentUser;
    if (existingUser != null) return existingUser;

    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Authentication did not return a user.');
    }
    return user;
  }
}
