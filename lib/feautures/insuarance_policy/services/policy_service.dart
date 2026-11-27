import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/policy.dart';

class PolicyService {
  final CollectionReference<Map<String, dynamic>> _policiesCollection =
      FirebaseFirestore.instance.collection('policies');

  // Get currently logged-in user's UID
  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    return user.uid;
  }

  // Get only current user's policies in real time
  Stream<List<Policy>> getPolicies() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<List<Policy>>.value(const <Policy>[]);
      }

      return _policiesCollection
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => Policy.fromMap(doc.data(), doc.id))
                .toList();
          });
    });
  }

  // Get one policy by ID
  Future<Policy?> getPolicyById(String id) async {
    final doc = await _policiesCollection.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    if (doc.data()!['userId'] != _currentUserId) {
      return null;
    }

    return Policy.fromMap(doc.data()!, doc.id);
  }

  // Add a new policy with current user's UID
  Future<void> addPolicy(Policy policy) async {
    final data = {...policy.toMap(), 'userId': _currentUserId};

    await _policiesCollection.doc(policy.policyId).set(data);
  }

  // Update an existing policy
  Future<void> updatePolicy(Policy policy) async {
    final doc = await _policiesCollection.doc(policy.policyId).get();

    if (!doc.exists || doc.data()?['userId'] != _currentUserId) {
      throw Exception('You cannot update this policy');
    }

    final data = {...policy.toMap(), 'userId': _currentUserId};

    await _policiesCollection.doc(policy.policyId).update(data);
  }

  // Delete a policy
  Future<void> removePolicy(String policyId) async {
    final doc = await _policiesCollection.doc(policyId).get();

    if (!doc.exists || doc.data()?['userId'] != _currentUserId) {
      throw Exception('You cannot delete this policy');
    }

    await _policiesCollection.doc(policyId).delete();
  }
}
