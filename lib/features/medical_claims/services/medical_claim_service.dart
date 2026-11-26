import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/medical_bill_document.dart';
import '../models/medical_claim.dart';
import '../models/medical_claim_status.dart';
import 'medical_claim_repository.dart';

enum MedicalClaimsViewFilter {
  all('All claims'),
  inProgress('In progress'),
  closed('Closed');

  const MedicalClaimsViewFilter(this.label);

  final String label;
}

class MedicalClaimService extends ChangeNotifier {
  MedicalClaimService({
    required this._repository,
    String? userId,
    bool autoLoad = true,
  }) : userId = _resolveUserId(userId) {
    if (autoLoad) {
      startWatching();
    }
  }

  /// Convenience factory for live production screens: uses the existing
  /// Firebase Auth session + shared `ClaimsService` & Supabase `StorageService`.
  factory MedicalClaimService.live({bool autoLoad = true}) {
    return MedicalClaimService(
      repository: FirestoreMedicalClaimRepository(),
      autoLoad: autoLoad,
    );
  }

  static String _resolveUserId(String? explicitUserId) {
    if (explicitUserId != null && explicitUserId.trim().isNotEmpty) {
      return explicitUserId.trim();
    }
    if (Firebase.apps.isNotEmpty) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        return uid;
      }
    }
    return 'DEMO-USER-01';
  }

  final MedicalClaimRepository _repository;
  final String userId;

  StreamSubscription<List<MedicalClaim>>? _claimsSubscription;
  List<MedicalClaim> _claims = const [];
  MedicalClaimsViewFilter _viewFilter = MedicalClaimsViewFilter.all;
  MedicalClaimStatus? _selectedStatusFilter;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _disposed = false;

  List<MedicalClaim> get claims => List.unmodifiable(_claims);

  MedicalClaimsViewFilter get viewFilter => _viewFilter;

  MedicalClaimStatus? get selectedStatusFilter => _selectedStatusFilter;

  String get searchQuery => _searchQuery;

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  static bool isInProgressStatus(MedicalClaimStatus status) =>
      status == MedicalClaimStatus.submitted ||
      status == MedicalClaimStatus.underReview ||
      status == MedicalClaimStatus.moreInfoRequired;

  static bool isClosedStatus(MedicalClaimStatus status) =>
      status == MedicalClaimStatus.approved ||
      status == MedicalClaimStatus.rejected;

  int get inProgressCount =>
      _claims.where((claim) => isInProgressStatus(claim.status)).length;

  int get closedCount =>
      _claims.where((claim) => isClosedStatus(claim.status)).length;

  List<MedicalClaim> get filteredClaims {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    return _claims.where((claim) {
      if (_selectedStatusFilter != null &&
          claim.status != _selectedStatusFilter) {
        return false;
      }

      final matchesGroup = switch (_viewFilter) {
        MedicalClaimsViewFilter.all => true,
        MedicalClaimsViewFilter.inProgress => isInProgressStatus(claim.status),
        MedicalClaimsViewFilter.closed => isClosedStatus(claim.status),
      };
      if (!matchesGroup) return false;
      if (normalizedQuery.isEmpty) return true;

      return claim.claimId.toLowerCase().contains(normalizedQuery) ||
          claim.hospitalName.toLowerCase().contains(normalizedQuery) ||
          claim.patientName.toLowerCase().contains(normalizedQuery) ||
          claim.treatmentType.toLowerCase().contains(normalizedQuery) ||
          claim.description.toLowerCase().contains(normalizedQuery) ||
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

  void setViewFilter(MedicalClaimsViewFilter filter) {
    if (_viewFilter == filter && _selectedStatusFilter == null) return;
    _viewFilter = filter;
    _selectedStatusFilter = null;
    _safeNotifyListeners();
  }

  void setStatusFilter(MedicalClaimStatus? status) {
    if (_selectedStatusFilter == status &&
        _viewFilter == MedicalClaimsViewFilter.all) {
      return;
    }
    _selectedStatusFilter = status;
    _viewFilter = MedicalClaimsViewFilter.all;
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

  Future<Uint8List?> downloadClaimDocument(MedicalBillDocument document) async {
    try {
      return await _repository.downloadDocument(
        storagePath: document.storagePath,
        localPreviewPath: document.localPreviewPath,
      );
    } catch (error) {
      _errorMessage = 'Failed to download medical document: $error';
      _safeNotifyListeners();
      return null;
    }
  }

  Future<bool> deleteClaimDocument({
    required String claimId,
    required MedicalBillDocument document,
  }) async {
    try {
      await _repository.deleteDocument(
        claimId: claimId,
        documentId: document.documentId,
        storagePath: document.storagePath,
      );
      final existing = findClaim(claimId);
      if (existing != null) {
        final updatedDocs = existing.documents
            .where((d) => d.documentId != document.documentId)
            .toList();
        _claims = [
          for (final c in _claims)
            if (c.claimId == claimId)
              c.copyWith(documents: updatedDocs)
            else
              c,
        ];
        _safeNotifyListeners();
      }
      return true;
    } catch (error) {
      _errorMessage = 'Failed to remove medical document: $error';
      _safeNotifyListeners();
      return false;
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
    List<PendingMedicalAttachment> attachments = const [],
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final resolvedUserId =
          (userId != null && userId.trim().isNotEmpty)
              ? userId.trim()
              : _resolveUserId(this.userId);
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
        attachments: attachments,
      );

      _claims = [
        savedClaim,
        for (final existing in _claims)
          if (existing.claimId != savedClaim.claimId) existing,
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
