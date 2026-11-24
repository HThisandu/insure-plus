import 'package:flutter/foundation.dart';

import '../../../common/models/claim_status.dart';
import '../../../common/services/supabase_app_service.dart';
import '../models/motor_claim.dart';

/// PostgreSQL access for Motor Claims.
///
/// The common claim fields are stored in the shared public.claims table.
/// Dates are sent as ISO-8601 strings and documents are stored as JSONB.
class MotorClaimSupabaseService {
  MotorClaimSupabaseService._();

  static final MotorClaimSupabaseService instance =
      MotorClaimSupabaseService._();

  static const String claimsTable = 'claims';

  bool get isSupabaseAvailable => SupabaseAppService.isInitialized;

  String generateClaimId() =>
      'CLM-MOT-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> saveClaimToSupabase(MotorClaim claim) async {
    try {
      await SupabaseAppService.client
          .from(claimsTable)
          .upsert(_toDatabaseMap(claim), onConflict: 'claim_id');
    } catch (error, stackTrace) {
      debugPrint('Supabase claim save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Updates only editable claim fields. Immutable identity, lifecycle and
  /// settlement columns are omitted so the database policies remain authoritative.
  Future<void> updateClaimInSupabase(MotorClaim claim) async {
    try {
      final data = _toDatabaseMap(claim)
        ..remove('claim_id')
        ..remove('user_id')
        ..remove('claim_type')
        ..remove('status')
        ..remove('created_at')
        ..remove('approved_amount');

      final rows = await SupabaseAppService.client
          .from(claimsTable)
          .update(data)
          .eq('claim_id', claim.claimId)
          .select('claim_id');

      if (rows.isEmpty) {
        throw StateError(
          'No editable claim was found for ${claim.claimId}. '
          'Check the signed-in user and claim status.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Supabase claim update failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<MotorClaim>> fetchClaimsFromSupabase({
    String? userId,
    String? policyId,
  }) async {
    try {
      var query = SupabaseAppService.client.from(claimsTable).select();

      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }
      if (policyId != null && policyId.isNotEmpty) {
        query = query.eq('policy_id', policyId);
      }

      final rows = await query.order('created_at', ascending: false);
      return rows
          .map(
            (row) => MotorClaim.fromMap(
              _fromDatabaseMap(Map<String, dynamic>.from(row)),
            ),
          )
          .where((claim) => claim.claimType == 'Motor Claim')
          .toList();
    } catch (error, stackTrace) {
      debugPrint('Supabase claim fetch failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<MotorClaim?> fetchClaimById(String claimId) async {
    final row = await SupabaseAppService.client
        .from(claimsTable)
        .select()
        .eq('claim_id', claimId)
        .maybeSingle();

    if (row == null) return null;
    return MotorClaim.fromMap(_fromDatabaseMap(Map<String, dynamic>.from(row)));
  }

  /// Client-side users cannot change claim decisions.
  /// The Supabase RLS policy also prevents status changes from this client.
  Future<void> updateClaimStatusInSupabase(
    String claimId,
    ClaimStatus newStatus, {
    String? notes,
    double? approvedAmount,
  }) async {
    final data = <String, dynamic>{'status': newStatus.value};
    if (notes != null) data['notes'] = notes;
    if (approvedAmount != null) data['approved_amount'] = approvedAmount;

    await SupabaseAppService.client
        .from(claimsTable)
        .update(data)
        .eq('claim_id', claimId);
  }

  Future<void> deleteClaimFromSupabase(String claimId) async {
    await SupabaseAppService.client
        .from(claimsTable)
        .delete()
        .eq('claim_id', claimId);
  }

  Map<String, dynamic> _toDatabaseMap(MotorClaim claim) {
    return {
      'claim_id': claim.claimId,
      'user_id': claim.userId,
      'policy_id': claim.policyId,
      'claim_type': claim.claimType,
      'claim_amount': claim.claimAmount,
      'description': claim.description,
      'status': claim.status.value,
      'documents': claim.documents
          .map(
            (doc) => {
              ...doc.toMap(),
              'uploadedAt': doc.uploadedAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
      'created_at': claim.createdAt.toUtc().toIso8601String(),
      'claimant_name': claim.claimantName,
      'contact_number': claim.contactNumber,
      'vehicle_registration_number': claim.vehicleRegistrationNumber,
      'vehicle_make': claim.vehicleMake,
      'vehicle_model': claim.vehicleModel,
      'vehicle_year': claim.vehicleYear,
      'vehicle_type': claim.vehicleType,
      'incident_date': claim.incidentDate.toIso8601String().split('T').first,
      'incident_time': claim.incidentTime,
      'incident_location': claim.incidentLocation,
      'incident_type': claim.incidentType,
      'damage_severity': claim.damageSeverity,
      'is_vehicle_drivable': claim.isVehicleDrivable,
      'police_report_filed': claim.policeReportFiled,
      'police_report_number': claim.policeReportNumber,
      'driver_name': claim.driverName,
      'driver_license_number': claim.driverLicenseNumber,
      'relationship_to_insured': claim.relationshipToInsured,
      'third_party_involved': claim.thirdPartyInvolved,
      'third_party_name': claim.thirdPartyName,
      'third_party_vehicle_number': claim.thirdPartyVehicleNumber,
      'third_party_contact': claim.thirdPartyContact,
      'third_party_insurance': claim.thirdPartyInsurance,
      'notes': claim.notes,
      'approved_amount': claim.approvedAmount,
    };
  }

  Map<String, dynamic> _fromDatabaseMap(Map<String, dynamic> row) {
    return {
      'claimId': row['claim_id'],
      'userId': row['user_id'],
      'policyId': row['policy_id'],
      'claimType': row['claim_type'],
      'claimAmount': row['claim_amount'],
      'description': row['description'],
      'status': row['status'],
      'documents': row['documents'] ?? const [],
      'createdAt': row['created_at'],
      'claimantName': row['claimant_name'],
      'contactNumber': row['contact_number'],
      'vehicleRegistrationNumber': row['vehicle_registration_number'],
      'vehicleMake': row['vehicle_make'],
      'vehicleModel': row['vehicle_model'],
      'vehicleYear': row['vehicle_year'],
      'vehicleType': row['vehicle_type'],
      'incidentDate': row['incident_date'],
      'incidentTime': row['incident_time'],
      'incidentLocation': row['incident_location'],
      'incidentType': row['incident_type'],
      'damageSeverity': row['damage_severity'],
      'isVehicleDrivable': row['is_vehicle_drivable'],
      'policeReportFiled': row['police_report_filed'],
      'policeReportNumber': row['police_report_number'],
      'driverName': row['driver_name'],
      'driverLicenseNumber': row['driver_license_number'],
      'relationshipToInsured': row['relationship_to_insured'],
      'thirdPartyInvolved': row['third_party_involved'],
      'thirdPartyName': row['third_party_name'],
      'thirdPartyVehicleNumber': row['third_party_vehicle_number'],
      'thirdPartyContact': row['third_party_contact'],
      'thirdPartyInsurance': row['third_party_insurance'],
      'notes': row['notes'],
      'approvedAmount': row['approved_amount'],
    };
  }
}
