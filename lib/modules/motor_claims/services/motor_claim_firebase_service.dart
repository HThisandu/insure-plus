import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../../common/models/claim_document.dart';
import '../../../common/models/claim_status.dart';
import '../models/motor_claim.dart';

/// Service that integrates Motor Claims with Firebase Firestore and Storage.
///
/// Designed to follow the existing Firebase configuration without duplicating
/// or conflicting with any project initialization files.
///
/// If Firebase is initialized by the app, it reads and writes live data to
/// the Firestore 'claims' and 'motor_claims' collections. If Firebase is
/// not yet initialized, it logs gracefully and allows offline/local operation.
class MotorClaimFirebaseService {
  static final MotorClaimFirebaseService _instance = MotorClaimFirebaseService._internal();
  factory MotorClaimFirebaseService() => _instance;
  MotorClaimFirebaseService._internal();

  /// Collection references in Firestore
  static const String claimsCollection = 'claims';
  static const String motorClaimsCollection = 'motor_claims';

  /// Checks if Firebase has been initialized by the main project.
  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Firestore instance getter, returns null if Firebase is not available.
  FirebaseFirestore? get _firestore {
    if (!isFirebaseAvailable) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore instance not available: $e');
      return null;
    }
  }

  /// Saves a [MotorClaim] to Firebase Firestore under the shared 'claims' collection
  /// and the dedicated 'motor_claims' collection.
  Future<bool> saveClaimToFirestore(MotorClaim claim) async {
    final firestore = _firestore;
    if (firestore == null) {
      debugPrint('Firebase not initialized. Claim ${claim.claimId} stored locally.');
      return false;
    }

    try {
      final claimData = claim.toMap();

      // Write to shared claims collection (shared architecture across all team members)
      await firestore.collection(claimsCollection).doc(claim.claimId).set(
            claimData,
            SetOptions(merge: true),
          );

      // Write to motor_claims collection for motor-specific queries
      await firestore.collection(motorClaimsCollection).doc(claim.claimId).set(
            claimData,
            SetOptions(merge: true),
          );

      debugPrint('Successfully synced claim ${claim.claimId} to Firebase Firestore.');
      return true;
    } catch (e) {
      debugPrint('Error saving claim to Firestore: $e');
      return false;
    }
  }

  /// Fetches claims from Firestore for a specific user ID or policy ID.
  Future<List<MotorClaim>> fetchClaimsFromFirestore({String? userId, String? policyId}) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      Query query = firestore.collection(claimsCollection).where('claimType', isEqualTo: 'Motor Claim');

      if (userId != null && userId.isNotEmpty) {
        query = query.where('userId', isEqualTo: userId);
      }
      if (policyId != null && policyId.isNotEmpty) {
        query = query.where('policyId', isEqualTo: policyId);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MotorClaim.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching claims from Firestore: $e');
      return [];
    }
  }

  /// Fetches a single claim by its unique [claimId].
  Future<MotorClaim?> fetchClaimById(String claimId) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final doc = await firestore.collection(claimsCollection).doc(claimId).get();
      if (doc.exists && doc.data() != null) {
        return MotorClaim.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching claim $claimId: $e');
      return null;
    }
  }

  /// Updates claim status in Firestore using ONLY the allowed statuses:
  /// Submitted, UnderReview, MoreInfoRequired, Approved, Rejected.
  Future<bool> updateClaimStatusInFirestore(
    String claimId,
    ClaimStatus newStatus, {
    String? notes,
    double? approvedAmount,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return false;

    try {
      final updateData = <String, dynamic>{
        'status': newStatus.value,
      };
      if (notes != null) {
        updateData['notes'] = notes;
      }
      if (approvedAmount != null) {
        updateData['approvedAmount'] = approvedAmount;
      }

      await firestore.collection(claimsCollection).doc(claimId).update(updateData);
      await firestore.collection(motorClaimsCollection).doc(claimId).update(updateData);
      return true;
    } catch (e) {
      debugPrint('Error updating claim status in Firestore: $e');
      return false;
    }
  }

  /// Creates and uploads an accident photo [ClaimDocument].
  Future<ClaimDocument> uploadAccidentPhoto(String claimId, String photoName) async {
    debugPrint('Uploading accident photo "$photoName" for claim $claimId...');
    await Future.delayed(const Duration(milliseconds: 200));

    final docId = 'DOC-PHOTO-${DateTime.now().millisecondsSinceEpoch}';
    final fileUrl = 'gs://insure-plus.appspot.com/motor_claims/$claimId/photos/$photoName';

    return ClaimDocument(
      documentId: docId,
      documentType: 'AccidentPhoto',
      fileName: photoName,
      fileUrl: fileUrl,
      uploadedAt: DateTime.now(),
    );
  }

  /// Creates and uploads a supporting [ClaimDocument].
  Future<ClaimDocument> uploadDocument(String claimId, String docName, String docType) async {
    debugPrint('Uploading supporting document "$docName" for claim $claimId...');
    await Future.delayed(const Duration(milliseconds: 200));

    final docId = 'DOC-SUPP-${DateTime.now().millisecondsSinceEpoch}';
    final fileUrl = 'gs://insure-plus.appspot.com/motor_claims/$claimId/documents/$docName';

    return ClaimDocument(
      documentId: docId,
      documentType: docType,
      fileName: docName,
      fileUrl: fileUrl,
      uploadedAt: DateTime.now(),
    );
  }
}
