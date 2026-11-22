import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/medical_bill_document.dart';
import '../models/medical_claim.dart';
import '../models/medical_claim_status.dart';
import 'medical_claim_repository.dart';

class MedicalClaimService extends ChangeNotifier {
  MedicalClaimService({
    required this._repository,
    this.userId = 'DEMO-USER-01',
    bool autoLoad = true,
  }) {
    if (autoLoad) {
      startWatching();
    }
  }

  final MedicalClaimRepository _repository;
  final String userId;

  StreamSubscription<List<MedicalClaim>>? _claimsSubscription;
  List<MedicalClaim> _claims = const [];
  MedicalClaimStatus? _selectedStatusFilter;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _disposed = false;

  List<MedicalClaim> get claims => List.unmodifiable(_claims);

  MedicalClaimStatus? get selectedStatusFilter => _selectedStatusFilter;

  String get searchQuery => _searchQuery;

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  List<MedicalClaim> get filteredClaims {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    return _claims.where((claim) {
      final matchesStatus =
          _selectedStatusFilter == null ||
          claim.status == _selectedStatusFilter;
      if (!matchesStatus) return false;
      if (normalizedQuery.isEmpty) return true;

      return claim.claimId.toLowerCase().contains(normalizedQuery) ||
          claim.hospitalName.toLowerCase().contains(normalizedQuery) ||
          claim.patientName.toLowerCase().contains(normalizedQuery) ||
          claim.treatmentType.toLowerCase().contains(normalizedQuery) ||
          (claim.billNumber?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList();
  }

  int countByStatus(MedicalClaimStatus status) =>
      _claims.where((claim) => claim.status == status).length;

  Map<MedicalClaimStatus, int> get statusCounts => {
    for (final status in MedicalClaimStatus.values)
      status: countByStatus(status),
  };

  double get totalClaimedAmount =>
      _claims.fold(0.0, (sum, claim) => sum + claim.claimAmount);

  double get approvedAmount => _claims
      .where((claim) => claim.status == MedicalClaimStatus.approved)
      .fold(0.0, (sum, claim) => sum + claim.claimAmount);

  MedicalClaim? findClaim(String claimId) {
    for (final claim in _claims) {
      if (claim.claimId == claimId) {
        return claim;
      }
    }
    return null;
  }

  void startWatching() {
    _claimsSubscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    _claimsSubscription = _repository.watchClaims(userId).listen(
      (claims) {
        _claims = List<MedicalClaim>.from(claims)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        _errorMessage = null;
        _safeNotifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = 'Failed to load medical claims: $error';
        _safeNotifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    startWatching();
  }

  void setStatusFilter(MedicalClaimStatus? status) {
    if (_selectedStatusFilter == status) return;
    _selectedStatusFilter = status;
    _safeNotifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _safeNotifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  Future<MedicalClaim?> getClaimById(String claimId) async {
    final cached = findClaim(claimId);
    if (cached != null) return cached;

    try {
      return await _repository.getClaimById(claimId);
    } catch (error) {
      _errorMessage = 'Failed to fetch claim details: $error';
      _safeNotifyListeners();
      return null;
    }
  }

  Future<MedicalClaim?> submitMedicalClaim({
    String? userId,
    required String policyId,
    required double claimAmount,
    required String description,
    required String patientName,
    required String patientRelationship,
    required String hospitalName,
    required String treatmentType,
    DateTime? admissionDate,
    DateTime? dischargeDate,
    String? billNumber,
    DateTime? billDate,
    List<MedicalBillDocument> documents = const [],
    String? localBillFilePath,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final resolvedUserId =
          (userId != null && userId.trim().isNotEmpty)
              ? userId.trim()
              : this.userId;
      final newClaim = MedicalClaim(
        claimId: '',
        userId: resolvedUserId,
        policyId: policyId.trim(),
        claimAmount: claimAmount,
        description: description.trim(),
        status: MedicalClaimStatus.submitted,
        documents: documents,
        createdAt: DateTime.now(),
        patientName: patientName.trim(),
        patientRelationship: patientRelationship,
        hospitalName: hospitalName.trim(),
        treatmentType: treatmentType,
        admissionDate: admissionDate,
        dischargeDate: dischargeDate,
        billNumber: billNumber?.trim().isEmpty ?? true
            ? null
            : billNumber!.trim(),
        billDate: billDate,
      );

      final savedClaim = await _repository.submitClaim(
        newClaim,
        localBillFilePath: localBillFilePath,
      );

      if (!_claims.any((claim) => claim.claimId == savedClaim.claimId)) {
        _claims = [savedClaim, ..._claims]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      _isSubmitting = false;
      _safeNotifyListeners();
      return savedClaim;
    } catch (error) {
      _isSubmitting = false;
      _errorMessage = 'Failed to submit medical claim: $error';
      _safeNotifyListeners();
      return null;
    }
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _claimsSubscription?.cancel();
    super.dispose();
  }
}
