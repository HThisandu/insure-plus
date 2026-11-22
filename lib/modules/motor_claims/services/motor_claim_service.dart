import 'package:flutter/foundation.dart';
import '../../../common/models/claim_document.dart';
import '../../../common/models/claim_status.dart';
import '../models/motor_claim.dart';
import 'motor_claim_firebase_service.dart';

/// Service managing Motor Claims state, mock data, and Firebase operations.
/// Extends [ChangeNotifier] for beginner-friendly, reactive UI updates.
class MotorClaimService extends ChangeNotifier {
  static final MotorClaimService _instance = MotorClaimService._internal();
  factory MotorClaimService() => _instance;

  final MotorClaimFirebaseService _firebaseService = MotorClaimFirebaseService();

  MotorClaimService._internal() {
    _initSampleData();
  }

  final List<MotorClaim> _claims = [];

  /// Returns an unmodifiable list of all motor claims.
  List<MotorClaim> get claims => List.unmodifiable(_claims);

  /// Access to the Firebase service
  MotorClaimFirebaseService get firebaseService => _firebaseService;

  /// Initializes realistic mock data adhering to the shared schema and ONLY the 5 allowed statuses:
  /// Submitted, UnderReview, MoreInfoRequired, Approved, Rejected.
  /// Each document contains: documentId, documentType, fileName, fileUrl, uploadedAt.
  void _initSampleData() {
    _claims.clear();
    _claims.addAll([
      MotorClaim(
        claimId: 'CLM-MOT-2026-001',
        userId: 'USR-78401',
        policyId: 'POL-MOT-88231',
        claimType: 'Motor Claim',
        claimantName: 'Alex Fernando',
        contactNumber: '+94 77 123 4567',
        incidentDate: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        description: 'Rear-ended by another vehicle at the traffic light intersection. Rear bumper and boot lid damaged.',
        claimAmount: 1850.00,
        status: ClaimStatus.underReview,
        vehicleRegistrationNumber: 'WP-CAD-4589',
        vehicleMake: 'Toyota',
        vehicleModel: 'Corolla Altis',
        vehicleYear: 2021,
        vehicleType: 'Car',
        incidentTime: '08:45 AM',
        incidentLocation: 'Galle Road, Bambalapitiya Junction',
        incidentType: 'Collision',
        damageSeverity: 'Moderate',
        isVehicleDrivable: true,
        policeReportFiled: true,
        policeReportNumber: 'PR-BAM-2026-908',
        driverName: 'Alex Fernando',
        driverLicenseNumber: 'B1894291',
        relationshipToInsured: 'Self',
        thirdPartyInvolved: true,
        thirdPartyName: 'Rohan Silva',
        thirdPartyVehicleNumber: 'WP-KQ-9912',
        thirdPartyContact: '+94 71 987 6543',
        thirdPartyInsurance: 'Sri Lanka Insurance Corp',
        documents: [
          ClaimDocument(
            documentId: 'DOC-PHOTO-001',
            documentType: 'AccidentPhoto',
            fileName: 'Rear_Bumper_Impact.jpg',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/Rear_Bumper_Impact.jpg',
            uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ClaimDocument(
            documentId: 'DOC-PHOTO-002',
            documentType: 'AccidentPhoto',
            fileName: 'Boot_Lid_Dent.jpg',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/Boot_Lid_Dent.jpg',
            uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ClaimDocument(
            documentId: 'DOC-SUPP-001',
            documentType: 'PoliceReport',
            fileName: 'Police_Entry_Slip.pdf',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/documents/Police_Entry_Slip.pdf',
            uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ClaimDocument(
            documentId: 'DOC-SUPP-002',
            documentType: 'DrivingLicense',
            fileName: 'Driving_License_Copy.jpg',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/documents/Driving_License_Copy.jpg',
            uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
        notes: 'Assessor assigned for physical garage inspection.',
      ),
      MotorClaim(
        claimId: 'CLM-MOT-2026-002',
        userId: 'USR-78402',
        policyId: 'POL-MOT-55912',
        claimType: 'Motor Claim',
        claimantName: 'Sarah Jenkins',
        contactNumber: '+94 76 543 2109',
        incidentDate: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        description: 'Tree branch fell onto the front windshield and bonnet during heavy monsoon storm.',
        claimAmount: 920.00,
        status: ClaimStatus.approved,
        approvedAmount: 920.00,
        vehicleRegistrationNumber: 'WP-CBC-1204',
        vehicleMake: 'Honda',
        vehicleModel: 'Vezel Hybrid',
        vehicleYear: 2020,
        vehicleType: 'SUV',
        incidentTime: '18:20 PM',
        incidentLocation: 'Flower Road, Colombo 07',
        incidentType: 'Natural Disaster',
        damageSeverity: 'Moderate',
        isVehicleDrivable: false,
        policeReportFiled: false,
        driverName: 'Sarah Jenkins',
        driverLicenseNumber: 'B7732910',
        relationshipToInsured: 'Self',
        thirdPartyInvolved: false,
        documents: [
          ClaimDocument(
            documentId: 'DOC-PHOTO-003',
            documentType: 'AccidentPhoto',
            fileName: 'Windshield_Shatter.jpg',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/Windshield_Shatter.jpg',
            uploadedAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
          ClaimDocument(
            documentId: 'DOC-PHOTO-004',
            documentType: 'AccidentPhoto',
            fileName: 'Bonnet_Branch_Damage.jpg',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/Bonnet_Branch_Damage.jpg',
            uploadedAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
          ClaimDocument(
            documentId: 'DOC-SUPP-003',
            documentType: 'RepairEstimate',
            fileName: 'Workshop_Quotation.pdf',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/documents/Workshop_Quotation.pdf',
            uploadedAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
        ],
        notes: 'Full amount approved. Cheque processed for authorized workshop.',
      ),
      MotorClaim(
        claimId: 'CLM-MOT-2026-003',
        userId: 'USR-78403',
        policyId: 'POL-MOT-33901',
        claimType: 'Motor Claim',
        claimantName: 'Kamal Perera',
        contactNumber: '+94 70 334 5566',
        incidentDate: DateTime.now().subtract(const Duration(hours: 14)),
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
        description: 'Side mirror broken and deep side-panel scratch while parked at supermarket parking lot.',
        claimAmount: 420.00,
        status: ClaimStatus.submitted,
        vehicleRegistrationNumber: 'SP-KU-8871',
        vehicleMake: 'Suzuki',
        vehicleModel: 'Swift RS',
        vehicleYear: 2019,
        vehicleType: 'Car',
        incidentTime: '15:10 PM',
        incidentLocation: 'Supermarket Car Park, Nugegoda',
        incidentType: 'Hit and Run / Parked Vehicle Damage',
        damageSeverity: 'Minor',
        isVehicleDrivable: true,
        policeReportFiled: true,
        policeReportNumber: 'PR-NUG-2026-412',
        driverName: 'Kamal Perera',
        driverLicenseNumber: 'B6654128',
        relationshipToInsured: 'Self',
        thirdPartyInvolved: false,
        documents: [
          ClaimDocument(
            documentId: 'DOC-PHOTO-005',
            documentType: 'AccidentPhoto',
            fileName: 'Broken_Side_Mirror.jpg',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/Broken_Side_Mirror.jpg',
            uploadedAt: DateTime.now().subtract(const Duration(hours: 10)),
          ),
          ClaimDocument(
            documentId: 'DOC-PHOTO-006',
            documentType: 'AccidentPhoto',
            fileName: 'Door_Panel_Scratch.jpg',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/Door_Panel_Scratch.jpg',
            uploadedAt: DateTime.now().subtract(const Duration(hours: 10)),
          ),
          ClaimDocument(
            documentId: 'DOC-SUPP-004',
            documentType: 'PoliceReport',
            fileName: 'Police_Entry_Copy.pdf',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/documents/Police_Entry_Copy.pdf',
            uploadedAt: DateTime.now().subtract(const Duration(hours: 10)),
          ),
        ],
        notes: 'Waiting for document review.',
      ),
      MotorClaim(
        claimId: 'CLM-MOT-2026-004',
        userId: 'USR-78404',
        policyId: 'POL-MOT-10293',
        claimType: 'Motor Claim',
        claimantName: 'David Wickramasinghe',
        contactNumber: '+94 72 889 0011',
        incidentDate: DateTime.now().subtract(const Duration(days: 8)),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        description: 'Front bumper hit while parking in basement. Additional clear close-up photos needed.',
        claimAmount: 650.00,
        status: ClaimStatus.moreInfoRequired,
        vehicleRegistrationNumber: 'WP-CAR-3329',
        vehicleMake: 'Nissan',
        vehicleModel: 'Leaf Electric',
        vehicleYear: 2018,
        vehicleType: 'Car',
        incidentTime: '11:00 AM',
        incidentLocation: 'Mall Basement Parking, Union Place',
        incidentType: 'Single Vehicle Accident',
        damageSeverity: 'Minor',
        isVehicleDrivable: true,
        policeReportFiled: false,
        driverName: 'David Wickramasinghe',
        driverLicenseNumber: 'B5541098',
        relationshipToInsured: 'Self',
        thirdPartyInvolved: false,
        documents: [
          ClaimDocument(
            documentId: 'DOC-PHOTO-007',
            documentType: 'AccidentPhoto',
            fileName: 'Bumper_Scrape.jpg',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/Bumper_Scrape.jpg',
            uploadedAt: DateTime.now().subtract(const Duration(days: 7)),
          ),
          ClaimDocument(
            documentId: 'DOC-SUPP-005',
            documentType: 'RepairEstimate',
            fileName: 'Workshop_Estimate.pdf',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/documents/Workshop_Estimate.pdf',
            uploadedAt: DateTime.now().subtract(const Duration(days: 7)),
          ),
        ],
        notes: 'Please upload clear close-up photo of the parking sensor mount to verify internal clips.',
      ),
      MotorClaim(
        claimId: 'CLM-MOT-2026-005',
        userId: 'USR-78405',
        policyId: 'POL-MOT-99100',
        claimType: 'Motor Claim',
        claimantName: 'Nuwan Jayawardena',
        contactNumber: '+94 78 444 8899',
        incidentDate: DateTime.now().subtract(const Duration(days: 20)),
        createdAt: DateTime.now().subtract(const Duration(days: 19)),
        description: 'Engine water damage claimed after driving through deeply flooded road.',
        claimAmount: 3200.00,
        status: ClaimStatus.rejected,
        vehicleRegistrationNumber: 'WP-CBA-9010',
        vehicleMake: 'BMW',
        vehicleModel: '320i',
        vehicleYear: 2022,
        vehicleType: 'Car',
        incidentTime: '21:30 PM',
        incidentLocation: 'High Level Road, Pannipitiya',
        incidentType: 'Water Ingress / Flooding',
        damageSeverity: 'Severe',
        isVehicleDrivable: false,
        policeReportFiled: false,
        driverName: 'Nuwan Jayawardena',
        driverLicenseNumber: 'B4412903',
        relationshipToInsured: 'Self',
        thirdPartyInvolved: false,
        documents: [
          ClaimDocument(
            documentId: 'DOC-PHOTO-008',
            documentType: 'AccidentPhoto',
            fileName: 'Engine_Bay_Flooded.jpg',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/Engine_Bay_Flooded.jpg',
            uploadedAt: DateTime.now().subtract(const Duration(days: 19)),
          ),
        ],
        notes: 'Hydrostatic lock caused by deliberately driving into standing water is excluded under Policy Clause 4.2.',
      ),
    ]);
  }

  /// Finds a specific claim by its unique [claimId].
  MotorClaim? getClaimById(String claimId) {
    try {
      return _claims.firstWhere((claim) => claim.claimId == claimId);
    } catch (_) {
      return null;
    }
  }

  /// Adds a new motor claim, persists to Firebase Firestore, and notifies listeners.
  void addClaim(MotorClaim claim) {
    _claims.insert(0, claim);
    notifyListeners();

    // Asynchronously sync with Firebase Firestore
    _firebaseService.saveClaimToFirestore(claim);
  }

  /// Updates an existing claim in local state and Firestore.
  void updateClaim(MotorClaim updatedClaim) {
    final index = _claims.indexWhere((c) => c.claimId == updatedClaim.claimId);
    if (index != -1) {
      _claims[index] = updatedClaim;
      notifyListeners();

      _firebaseService.saveClaimToFirestore(updatedClaim);
    }
  }

  /// Deletes or withdraws a claim by ID.
  bool deleteClaim(String claimId) {
    final initialCount = _claims.length;
    _claims.removeWhere((claim) => claim.claimId == claimId);
    final wasRemoved = _claims.length < initialCount;
    if (wasRemoved) {
      notifyListeners();
    }
    return wasRemoved;
  }

  /// Updates status and optional notes or approved amount for demonstration.
  /// Allowed statuses ONLY: Submitted, UnderReview, MoreInfoRequired, Approved, Rejected.
  void updateClaimStatus(
    String claimId,
    ClaimStatus newStatus, {
    String? notes,
    double? approvedAmount,
  }) {
    final index = _claims.indexWhere((c) => c.claimId == claimId);
    if (index != -1) {
      final existing = _claims[index];
      _claims[index] = existing.copyWith(
        status: newStatus,
        notes: notes ?? existing.notes,
        approvedAmount: approvedAmount ?? existing.approvedAmount,
      );
      notifyListeners();

      _firebaseService.updateClaimStatusInFirestore(
        claimId,
        newStatus,
        notes: notes,
        approvedAmount: approvedAmount,
      );
    }
  }

  /// Filters claims by optional status and search text.
  List<MotorClaim> getFilteredClaims({
    ClaimStatus? status,
    String searchQuery = '',
  }) {
    return _claims.where((claim) {
      final matchesStatus = status == null || claim.status == status;
      final q = searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          claim.claimId.toLowerCase().contains(q) ||
          claim.vehicleRegistrationNumber.toLowerCase().contains(q) ||
          claim.claimantName.toLowerCase().contains(q) ||
          claim.vehicleMake.toLowerCase().contains(q) ||
          claim.vehicleModel.toLowerCase().contains(q) ||
          claim.policyId.toLowerCase().contains(q) ||
          claim.userId.toLowerCase().contains(q);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  /// Returns summary statistics for ONLY the 5 allowed statuses.
  Map<String, int> getStatistics() {
    int total = _claims.length;
    int submitted = 0;
    int underReview = 0;
    int moreInfoRequired = 0;
    int approved = 0;
    int rejected = 0;

    for (final claim in _claims) {
      switch (claim.status) {
        case ClaimStatus.submitted:
          submitted++;
          break;
        case ClaimStatus.underReview:
          underReview++;
          break;
        case ClaimStatus.moreInfoRequired:
          moreInfoRequired++;
          break;
        case ClaimStatus.approved:
          approved++;
          break;
        case ClaimStatus.rejected:
          rejected++;
          break;
      }
    }

    return {
      'total': total,
      'submitted': submitted,
      'underReview': underReview,
      'moreInfoRequired': moreInfoRequired,
      'approved': approved,
      'rejected': rejected,
    };
  }

  /// Calculates total estimated claim value across all claims.
  double getTotalClaimAmount() {
    return _claims.fold(0.0, (sum, claim) => sum + claim.claimAmount);
  }

  /// Generates a sequential, user-friendly Claim ID.
  String generateNextClaimId() {
    final nextNumber = _claims.length + 1;
    final padded = nextNumber.toString().padLeft(3, '0');
    return 'CLM-MOT-2026-$padded';
  }

  /// Resets mock data back to sample defaults.
  void resetToDefaultData() {
    _initSampleData();
    notifyListeners();
  }
}
