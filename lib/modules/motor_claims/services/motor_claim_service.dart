import 'package:flutter/foundation.dart';

import '../../../common/models/claim_status.dart';
import '../models/motor_claim.dart';
import 'firebase_auth_service.dart';
import 'motor_claim_storage_service.dart';
import 'motor_claim_supabase_service.dart';

/// Reactive Motor Claims state backed by Firebase Authentication and Supabase.
/// No hard-coded sample claims are inserted into the real user's claim list.
class MotorClaimService extends ChangeNotifier {
  MotorClaimService._internal() {
    refreshClaims();
  }

  static final MotorClaimService _instance = MotorClaimService._internal();
  factory MotorClaimService() => _instance;

  final MotorClaimSupabaseService _supabaseService =
      MotorClaimSupabaseService.instance;
  final FirebaseAuthService _authService = FirebaseAuthService.instance;

  final List<MotorClaim> _claims = [];
  bool _isLoading = false;
  String? _lastError;

  List<MotorClaim> get claims => List.unmodifiable(_claims);
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  MotorClaimSupabaseService get supabaseService => _supabaseService;

  /// Loads only the signed-in user's motor claims from Supabase.
  Future<void> refreshClaims() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final user = await _authService.ensureSignedIn();
      final loaded = await _supabaseService.fetchClaimsFromSupabase(
        userId: user.uid,
      );
      _claims
        ..clear()
        ..addAll(loaded);
    } catch (error) {
      _lastError = error.toString();
      debugPrint('Could not refresh motor claims: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  MotorClaim? getClaimById(String claimId) {
    for (final claim in _claims) {
      if (claim.claimId == claimId) return claim;
    }
    return null;
  }

  String generateNextClaimId() => _supabaseService.generateClaimId();

  /// Saves to Supabase first. The UI is updated only after a successful save.
  Future<void> addClaim(MotorClaim claim) async {
    await _supabaseService.saveClaimToSupabase(claim);
    _claims.insert(0, claim);
    notifyListeners();
  }

  Future<void> updateClaim(MotorClaim updatedClaim) async {
    await _supabaseService.updateClaimInSupabase(updatedClaim);
    final index = _claims.indexWhere(
      (item) => item.claimId == updatedClaim.claimId,
    );
    if (index == -1) {
      _claims.insert(0, updatedClaim);
    } else {
      _claims[index] = updatedClaim;
    }
    notifyListeners();
  }

  Future<void> updateClaimStatus(
    String claimId,
    ClaimStatus newStatus, {
    String? notes,
    double? approvedAmount,
  }) async {
    await _supabaseService.updateClaimStatusInSupabase(
      claimId,
      newStatus,
      notes: notes,
      approvedAmount: approvedAmount,
    );

    final index = _claims.indexWhere((item) => item.claimId == claimId);
    if (index >= 0) {
      _claims[index] = _claims[index].copyWith(
        status: newStatus,
        notes: notes ?? _claims[index].notes,
        approvedAmount: approvedAmount ?? _claims[index].approvedAmount,
      );
      notifyListeners();
    }
  }

  Future<void> deleteClaim(String claimId) async {
    // Remove private uploaded objects before deleting the claim row.
    // If a file removal fails, keep the claim record so the user can retry.
    final claim =
        getClaimById(claimId) ?? await _supabaseService.fetchClaimById(claimId);
    if (claim != null) {
      final storage = MotorClaimStorageService.instance;
      for (final document in claim.documents) {
        final objectPath = document.fileUrl;
        if (objectPath.isNotEmpty && !objectPath.startsWith('gs://')) {
          await storage.deleteClaimFile(objectPath);
        }
      }
    }

    await _supabaseService.deleteClaimFromSupabase(claimId);
    _claims.removeWhere((claim) => claim.claimId == claimId);
    notifyListeners();
  }

  List<MotorClaim> getFilteredClaims({
    ClaimStatus? status,
    String searchQuery = '',
  }) {
    return _claims.where((claim) {
      final matchesStatus = status == null || claim.status == status;
      final query = searchQuery.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          claim.claimId.toLowerCase().contains(query) ||
          claim.vehicleRegistrationNumber.toLowerCase().contains(query) ||
          claim.claimantName.toLowerCase().contains(query) ||
          claim.vehicleMake.toLowerCase().contains(query) ||
          claim.vehicleModel.toLowerCase().contains(query) ||
          claim.policyId.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Map<String, int> getStatistics() {
    final result = <String, int>{
      'total': _claims.length,
      'submitted': 0,
      'underReview': 0,
      'moreInfoRequired': 0,
      'approved': 0,
      'rejected': 0,
    };
    for (final claim in _claims) {
      switch (claim.status) {
        case ClaimStatus.submitted:
          result['submitted'] = result['submitted']! + 1;
        case ClaimStatus.underReview:
          result['underReview'] = result['underReview']! + 1;
        case ClaimStatus.moreInfoRequired:
          result['moreInfoRequired'] = result['moreInfoRequired']! + 1;
        case ClaimStatus.approved:
          result['approved'] = result['approved']! + 1;
        case ClaimStatus.rejected:
          result['rejected'] = result['rejected']! + 1;
      }
    }
    return result;
  }

  double getTotalClaimAmount() =>
      _claims.fold(0.0, (total, claim) => total + claim.claimAmount);

  /// Clears only the in-memory list. It never inserts fabricated demo records.
  void resetToDefaultData() {
    _claims.clear();
    notifyListeners();
  }
}
