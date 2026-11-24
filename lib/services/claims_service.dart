import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'storage_service.dart';

class ClaimsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addClaimDocument({
    required String claimId,
    required String documentType,
    required String fileName,
    required String storagePath,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final claimRef = _firestore.collection('claims').doc(claimId);
    final claimSnapshot = await claimRef.get();

    if (!claimSnapshot.exists) {
      throw Exception('Claim not found');
    }

    if (claimSnapshot.data()?['userId'] != user.uid) {
      throw Exception('You cannot modify this claim');
    }

    await claimRef.update({
      'documents': FieldValue.arrayUnion([
        {
          'documentId': claimRef.collection('documents').doc().id,
          'documentType': documentType,
          'fileName': fileName,
          'storagePath': storagePath,
          'uploadedAt': Timestamp.now(),
        },
      ]),
    });
  }

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

  // Get all claims (Admin and Operations Staff)
  Future<QuerySnapshot> getAllClaims() async {
    return await _firestore.collection('claims').get();
  }

  // Update claim status (Admin and Operations Staff only)
  Future<void> updateClaimStatus({
    required String claimId,
    required String newStatus,
  }) async {
    const allowedStatuses = [
      'Submitted',
      'UnderReview',
      'MoreInfoRequired',
      'Approved',
      'Rejected',
    ];

    if (!allowedStatuses.contains(newStatus)) {
      throw Exception('Invalid claim status');
    }

    await _firestore.collection('claims').doc(claimId).update({
      'status': newStatus,
    });
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

  Future<void> removeClaimDocument({
    required String claimId,
    required String documentId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    final claimRef = _firestore.collection('claims').doc(claimId);
    final claimSnapshot = await claimRef.get();

    if (!claimSnapshot.exists) {
      throw Exception('Claim not found');
    }

    final claimData = claimSnapshot.data()!;

    if (claimData['userId'] != user.uid) {
      throw Exception('You cannot modify this claim');
    }

    final documents = List<Map<String, dynamic>>.from(
      claimData['documents'] ?? [],
    );

    final documentIndex = documents.indexWhere(
      (document) => document['documentId'] == documentId,
    );

    if (documentIndex == -1) {
      throw Exception('Document not found');
    }

    final storagePath = documents[documentIndex]['storagePath'];

    if (storagePath == null || storagePath is! String) {
      throw Exception('Invalid document storage path');
    }

    // 1. Delete actual file from Supabase Storage
    await StorageService().deleteClaimDocument(storagePath: storagePath);

    // 2. Remove document metadata from Firestore
    documents.removeAt(documentIndex);

    await claimRef.update({'documents': documents});
  }
}
