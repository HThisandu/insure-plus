
import 'package:firebase_auth/firebase_auth.dart';
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
    // 1. Create Firebase Authentication account
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Get Firebase UID
    final uid = userCredential.user!.uid;

    // 3. Create Firestore user document
    await _firestore.collection('users').doc(uid).set({
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': 'Policyholder',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
