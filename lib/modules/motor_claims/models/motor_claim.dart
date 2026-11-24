import '../../../common/models/claim.dart';
import '../../../common/models/claim_document.dart';
import '../../../common/models/claim_status.dart';
import 'claim_milestone.dart';

/// Motor Claim Model representing vehicle insurance claims in Insure-Plus.
/// Extends the common [Claim] base model adhering strictly to the shared schema:
/// [claimId], [userId], [policyId], [claimType], [claimAmount], [description],
/// [status], [documents], [createdAt].
///
/// Allowed statuses ONLY:
/// Submitted, UnderReview, MoreInfoRequired, Approved, Rejected.
///
/// Each document in [documents] contains:
/// [documentId], [documentType], [fileName], [fileUrl], [uploadedAt].
class MotorClaim extends Claim {
  // Vehicle Information
  final String claimantName;
  final String contactNumber;
  final String vehicleRegistrationNumber;
  final String vehicleMake;
  final String vehicleModel;
  final int vehicleYear;
  final String vehicleType; // Car, SUV, Motorcycle, Van, Commercial

  // Incident & Accident Details
  final DateTime incidentDate;
  final String incidentTime;
  final String incidentLocation;
  final String incidentType; // Collision, Natural Disaster, Theft, etc.
  final String damageSeverity; // Minor, Moderate, Severe
  final bool isVehicleDrivable;
  final bool policeReportFiled;
  final String? policeReportNumber;

  // Driver Details
  final String driverName;
  final String driverLicenseNumber;
  final String relationshipToInsured; // Self, Spouse, Child, Authorized Driver

  // Third-Party Details
  final bool thirdPartyInvolved;
  final String? thirdPartyName;
  final String? thirdPartyVehicleNumber;
  final String? thirdPartyContact;
  final String? thirdPartyInsurance;

  // Additional Notes & Settlement
  final String? notes;
  final double? approvedAmount;

  MotorClaim({
    required super.claimId,
    required super.userId,
    required super.policyId,
    super.claimType = 'Motor Claim',
    required super.claimAmount,
    required super.description,
    super.status = ClaimStatus.submitted,
    super.documents = const [],
    super.createdAt,
    required this.claimantName,
    required this.contactNumber,
    required this.vehicleRegistrationNumber,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    this.vehicleType = 'Car',
    required this.incidentDate,
    required this.incidentTime,
    required this.incidentLocation,
    required this.incidentType,
    this.damageSeverity = 'Moderate',
    this.isVehicleDrivable = true,
    this.policeReportFiled = false,
    this.policeReportNumber,
    required this.driverName,
    required this.driverLicenseNumber,
    this.relationshipToInsured = 'Self',
    this.thirdPartyInvolved = false,
    this.thirdPartyName,
    this.thirdPartyVehicleNumber,
    this.thirdPartyContact,
    this.thirdPartyInsurance,
    this.notes,
    this.approvedAmount,
  });

  /// Helper to get all accident photos from the shared [documents] list.
  List<ClaimDocument> get accidentPhotos =>
      documents.where((d) => d.documentType == 'AccidentPhoto').toList();

  /// Helper to get all non-photo supporting documents from the shared [documents] list.
  List<ClaimDocument> get supportingDocuments =>
      documents.where((d) => d.documentType != 'AccidentPhoto').toList();

  /// Full vehicle display title e.g. "2022 Toyota Corolla (WP-CAD-4589)"
  String get vehicleDisplayName {
    return '$vehicleYear $vehicleMake $vehicleModel ($vehicleRegistrationNumber)';
  }

  /// Formatted incident date as YYYY-MM-DD
  String get formattedIncidentDate {
    return '${incidentDate.year}-${incidentDate.month.toString().padLeft(2, '0')}-${incidentDate.day.toString().padLeft(2, '0')}';
  }

  /// Calculates visual tracking milestones based ONLY on the 5 allowed statuses:
  /// Submitted, UnderReview, MoreInfoRequired, Approved, Rejected.
  List<ClaimMilestone> get trackingMilestones {
    final formattedDate = formattedSubmissionDate;

    if (status == ClaimStatus.rejected) {
      return [
        ClaimMilestone(
          title: 'Claim Submitted',
          description: 'Claim application registered in Insure-Plus portal.',
          date: formattedDate,
          isCompleted: true,
          isCurrent: false,
        ),
        ClaimMilestone(
          title: 'Technical Review',
          description: 'Vehicle damage assessment & police report examined.',
          date: formattedDate,
          isCompleted: true,
          isCurrent: false,
        ),
        ClaimMilestone(
          title: 'Claim Rejected',
          description: notes ?? 'Claim rejected based on policy coverage assessment.',
          date: formattedDate,
          isCompleted: false,
          isCurrent: true,
        ),
      ];
    }

    if (status == ClaimStatus.moreInfoRequired) {
      return [
        ClaimMilestone(
          title: 'Claim Submitted',
          description: 'Claim application registered in Insure-Plus portal.',
          date: formattedDate,
          isCompleted: true,
          isCurrent: false,
        ),
        ClaimMilestone(
          title: 'Initial Review',
          description: 'Preliminary inspection completed by assessor.',
          date: formattedDate,
          isCompleted: true,
          isCurrent: false,
        ),
        ClaimMilestone(
          title: 'More Info Required',
          description: notes ?? 'Additional accident photos or police abstract requested.',
          date: formattedDate,
          isCompleted: false,
          isCurrent: true,
        ),
        const ClaimMilestone(
          title: 'Final Decision',
          description: 'Assessment decision pending receipt of requested info.',
          date: 'Pending',
          isCompleted: false,
          isCurrent: false,
        ),
      ];
    }

    final isSubmitted = status == ClaimStatus.submitted;
    final isUnderReview = status == ClaimStatus.underReview;
    final isApproved = status == ClaimStatus.approved;

    return [
      ClaimMilestone(
        title: 'Claim Submitted',
        description: 'Claim registered and stored in Insure-Plus system.',
        date: formattedDate,
        isCompleted: true,
        isCurrent: isSubmitted,
      ),
      ClaimMilestone(
        title: 'Document & Photo Verification',
        description: 'Accident photos (${accidentPhotos.length}) and documents (${supportingDocuments.length}) verified.',
        date: isSubmitted ? 'In Progress' : formattedDate,
        isCompleted: !isSubmitted,
        isCurrent: isUnderReview,
      ),
      ClaimMilestone(
        title: 'Garage & Damage Assessment',
        description: 'Authorized motor engineer assesses repair quotation.',
        date: isApproved ? formattedDate : 'Estimated: 2 business days',
        isCompleted: isApproved,
        isCurrent: false,
      ),
      ClaimMilestone(
        title: 'Claim Approved',
        description: isApproved
            ? 'Approved for payout of \$${(approvedAmount ?? claimAmount).toStringAsFixed(2)}'
            : 'Final decision pending inspection results.',
        date: isApproved ? formattedDate : 'Estimated: 3-5 business days',
        isCompleted: isApproved,
        isCurrent: isApproved,
      ),
    ];
  }

  /// Converts the Motor Claim into a Map for backend persistence.
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'claimantName': claimantName,
      'contactNumber': contactNumber,
      'vehicleRegistrationNumber': vehicleRegistrationNumber,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'vehicleType': vehicleType,
      'incidentDate': incidentDate,
      'incidentTime': incidentTime,
      'incidentLocation': incidentLocation,
      'incidentType': incidentType,
      'damageSeverity': damageSeverity,
      'isVehicleDrivable': isVehicleDrivable,
      'policeReportFiled': policeReportFiled,
      'policeReportNumber': policeReportNumber,
      'driverName': driverName,
      'driverLicenseNumber': driverLicenseNumber,
      'relationshipToInsured': relationshipToInsured,
      'thirdPartyInvolved': thirdPartyInvolved,
      'thirdPartyName': thirdPartyName,
      'thirdPartyVehicleNumber': thirdPartyVehicleNumber,
      'thirdPartyContact': thirdPartyContact,
      'thirdPartyInsurance': thirdPartyInsurance,
      'notes': notes,
      'approvedAmount': approvedAmount,
    });
    return map;
  }

  /// Factory constructor to deserialize a MotorClaim from a Map (e.g. from Firestore).
  factory MotorClaim.fromMap(Map<String, dynamic> map) {
    // Parse documents list
    List<ClaimDocument> docs = [];
    if (map['documents'] is List) {
      docs = (map['documents'] as List<dynamic>).map((item) {
        if (item is Map<String, dynamic>) {
          return ClaimDocument.fromMap(item);
        } else if (item is Map) {
          return ClaimDocument.fromMap(Map<String, dynamic>.from(item));
        } else if (item is String) {
          final isPhoto = item.toLowerCase().endsWith('.jpg') || item.toLowerCase().endsWith('.png');
          return ClaimDocument(
            documentId: 'DOC-${item.hashCode.abs()}',
            documentType: isPhoto ? 'AccidentPhoto' : 'SupportingDocument',
            fileName: item,
            fileUrl: 'gs://insure-plus.appspot.com/claims/$item',
          );
        }
        return ClaimDocument(
          documentId: 'DOC-UNKNOWN',
          documentType: 'General',
          fileName: 'document',
          fileUrl: '',
        );
      }).toList();
    }

    // Merge any accidentPhotos from map if present
    if (map['accidentPhotos'] is List) {
      for (final p in (map['accidentPhotos'] as List<dynamic>)) {
        final pName = p.toString();
        if (!docs.any((d) => d.fileName == pName)) {
          docs.add(
            ClaimDocument(
              documentId: 'PHOTO-${pName.hashCode.abs()}',
              documentType: 'AccidentPhoto',
              fileName: pName,
              fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/$pName',
            ),
          );
        }
      }
    }

    return MotorClaim(
      claimId: map['claimId'] as String? ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? 'USR-DEFAULT',
      policyId: map['policyId'] as String? ?? map['policyNumber'] as String? ?? '',
      claimType: map['claimType'] as String? ?? 'Motor Claim',
      claimAmount: (map['claimAmount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      status: ClaimStatus.fromString(map['status'] as String? ?? 'Submitted'),
      documents: docs,
      createdAt: _readMotorClaimDateTime(map['createdAt'] ?? map['submissionDate']),
      claimantName: map['claimantName'] as String? ?? 'Insured Customer',
      contactNumber: map['contactNumber'] as String? ?? '',
      vehicleRegistrationNumber: map['vehicleRegistrationNumber'] as String? ?? '',
      vehicleMake: map['vehicleMake'] as String? ?? '',
      vehicleModel: map['vehicleModel'] as String? ?? '',
      vehicleYear: (map['vehicleYear'] as num?)?.toInt() ?? 2022,
      vehicleType: map['vehicleType'] as String? ?? 'Car',
      incidentDate: _readMotorClaimDateTime(map['incidentDate']),
      incidentTime: map['incidentTime'] as String? ?? '12:00 PM',
      incidentLocation: map['incidentLocation'] as String? ?? '',
      incidentType: map['incidentType'] as String? ?? 'Collision',
      damageSeverity: map['damageSeverity'] as String? ?? 'Moderate',
      isVehicleDrivable: map['isVehicleDrivable'] as bool? ?? true,
      policeReportFiled: map['policeReportFiled'] as bool? ?? false,
      policeReportNumber: map['policeReportNumber'] as String?,
      driverName: map['driverName'] as String? ?? '',
      driverLicenseNumber: map['driverLicenseNumber'] as String? ?? '',
      relationshipToInsured: map['relationshipToInsured'] as String? ?? 'Self',
      thirdPartyInvolved: map['thirdPartyInvolved'] as bool? ?? false,
      thirdPartyName: map['thirdPartyName'] as String?,
      thirdPartyVehicleNumber: map['thirdPartyVehicleNumber'] as String?,
      thirdPartyContact: map['thirdPartyContact'] as String?,
      thirdPartyInsurance: map['thirdPartyInsurance'] as String?,
      notes: map['notes'] as String?,
      approvedAmount: (map['approvedAmount'] as num?)?.toDouble(),
    );
  }

  /// Creates a copy of this MotorClaim with optional updated fields.
  MotorClaim copyWith({
    String? claimId,
    String? userId,
    String? policyId,
    String? claimType,
    double? claimAmount,
    String? description,
    ClaimStatus? status,
    List<ClaimDocument>? documents,
    DateTime? createdAt,
    String? claimantName,
    String? contactNumber,
    String? vehicleRegistrationNumber,
    String? vehicleMake,
    String? vehicleModel,
    int? vehicleYear,
    String? vehicleType,
    DateTime? incidentDate,
    String? incidentTime,
    String? incidentLocation,
    String? incidentType,
    String? damageSeverity,
    bool? isVehicleDrivable,
    bool? policeReportFiled,
    String? policeReportNumber,
    String? driverName,
    String? driverLicenseNumber,
    String? relationshipToInsured,
    bool? thirdPartyInvolved,
    String? thirdPartyName,
    String? thirdPartyVehicleNumber,
    String? thirdPartyContact,
    String? thirdPartyInsurance,
    String? notes,
    double? approvedAmount,
  }) {
    return MotorClaim(
      claimId: claimId ?? this.claimId,
      userId: userId ?? this.userId,
      policyId: policyId ?? this.policyId,
      claimType: claimType ?? this.claimType,
      claimAmount: claimAmount ?? this.claimAmount,
      description: description ?? this.description,
      status: status ?? this.status,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      claimantName: claimantName ?? this.claimantName,
      contactNumber: contactNumber ?? this.contactNumber,
      vehicleRegistrationNumber: vehicleRegistrationNumber ?? this.vehicleRegistrationNumber,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleType: vehicleType ?? this.vehicleType,
      incidentDate: incidentDate ?? this.incidentDate,
      incidentTime: incidentTime ?? this.incidentTime,
      incidentLocation: incidentLocation ?? this.incidentLocation,
      incidentType: incidentType ?? this.incidentType,
      damageSeverity: damageSeverity ?? this.damageSeverity,
      isVehicleDrivable: isVehicleDrivable ?? this.isVehicleDrivable,
      policeReportFiled: policeReportFiled ?? this.policeReportFiled,
      policeReportNumber: policeReportNumber ?? this.policeReportNumber,
      driverName: driverName ?? this.driverName,
      driverLicenseNumber: driverLicenseNumber ?? this.driverLicenseNumber,
      relationshipToInsured: relationshipToInsured ?? this.relationshipToInsured,
      thirdPartyInvolved: thirdPartyInvolved ?? this.thirdPartyInvolved,
      thirdPartyName: thirdPartyName ?? this.thirdPartyName,
      thirdPartyVehicleNumber: thirdPartyVehicleNumber ?? this.thirdPartyVehicleNumber,
      thirdPartyContact: thirdPartyContact ?? this.thirdPartyContact,
      thirdPartyInsurance: thirdPartyInsurance ?? this.thirdPartyInsurance,
      notes: notes ?? this.notes,
      approvedAmount: approvedAmount ?? this.approvedAmount,
    );
  }
}

DateTime _readMotorClaimDateTime(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}
