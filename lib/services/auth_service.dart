import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    UserCredential? userCredential;

    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;

      await _firestore.collection('users').doc(user.uid).set({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': 'Policyholder',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (userCredential?.user != null) {
        await userCredential!.user!.delete();
      }

      rethrow;
    }
  }

  Future<UserCredential> loginUser({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    if (kIsWeb) {
      await _auth.setPersistence(
        rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );
    }
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found') rethrow;
    }
  }

  DocumentReference<Map<String, dynamic>> profile(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<void> logoutUser() async {
    await _auth.signOut();
  }
}
