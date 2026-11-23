import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClaimsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<QuerySnapshot> getUserClaims() async {
    // 1. Get current logged-in user
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    // 2. Get claims belonging to this user
    return await _firestore
        .collection('claims')
        .where('userId', isEqualTo: user.uid)
        .get();
  }

  Future<String> submitClaim({
    required String policyId,
    required String claimType,
    required double claimAmount,
    required String description,
  }) async {
    // 1. Get current logged-in user
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    // 2. Generate Claim ID
    final claimRef = _firestore.collection('claims').doc();

    // 3. Save claim details to Firestore
    await claimRef.set({
      'claimId': claimRef.id,
      'userId': user.uid,
      'policyId': policyId,
      'claimType': claimType,
      'claimAmount': claimAmount,
      'description': description,
      'status': 'Submitted',
      'documents': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return claimRef.id;
  }
}
