import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/policy.dart';

class PolicyService {
  final CollectionReference<Map<String, dynamic>> _policiesCollection =
      FirebaseFirestore.instance.collection('policies');

  // Get all policies in real time
  Stream<List<Policy>> getPolicies() {
    return _policiesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Policy.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get one policy by ID
  Future<Policy?> getPolicyById(String id) async {
    final doc = await _policiesCollection.doc(id).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return Policy.fromMap(doc.data()!, doc.id);
  }

  // Add a new policy
  Future<void> addPolicy(Policy policy) async {
    await _policiesCollection.doc(policy.policyId).set(policy.toMap());
  }

  // Update an existing policy
  Future<void> updatePolicy(Policy policy) async {
    await _policiesCollection.doc(policy.policyId).update(policy.toMap());
  }

  // Delete a policy
  Future<void> removePolicy(String policyId) async {
    await _policiesCollection.doc(policyId).delete();
  }
}
