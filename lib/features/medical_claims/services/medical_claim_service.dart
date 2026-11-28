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
    required this.repository,
    String? userId,
    bool autoLoad = true,
  }) : userId = _getCurrentUserId(userId) {
    if (autoLoad) {
      startWatching();
    }
  }

  factory MedicalClaimService.live({bool autoLoad = true}) {
    return MedicalClaimService(
      repository: FirestoreMedicalClaimRepository(),
      autoLoad: autoLoad,
    );
  }

  static String _getCurrentUserId(String? givenUserId) {
    if (givenUserId != null && givenUserId.trim().isNotEmpty) {
      return givenUserId.trim();
    }
    if (Firebase.apps.isNotEmpty) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) return uid;
    }
    return 'DEMO-USER-01';
  }

  final MedicalClaimRepository repository;
  final String userId;

  StreamSubscription<List<MedicalClaim>>? _subscription;
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
      _claims.where((c) => isInProgressStatus(c.status)).length;

  int get closedCount =>
      _claims.where((c) => isClosedStatus(c.status)).length;

  List<MedicalClaim> get filteredClaims {
    final query = _searchQuery.trim().toLowerCase();
    return _claims.where((claim) {
      if (_selectedStatusFilter != null &&
          claim.status != _selectedStatusFilter) {
        return false;
      }

      if (_viewFilter == MedicalClaimsViewFilter.inProgress &&
          !isInProgressStatus(claim.status)) {
        return false;
      }
      if (_viewFilter == MedicalClaimsViewFilter.closed &&
          !isClosedStatus(claim.status)) {
        return false;
      }

      if (query.isEmpty) return true;

      return claim.claimId.toLowerCase().contains(query) ||
          claim.hospitalName.toLowerCase().contains(query) ||
          claim.patientName.toLowerCase().contains(query) ||
          claim.treatmentType.toLowerCase().contains(query) ||
          (claim.billNumber?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  int countByStatus(MedicalClaimStatus status) =>
      _claims.where((c) => c.status == status).length;

  MedicalClaim? findClaim(String claimId) {
    for (final claim in _claims) {
      if (claim.claimId == claimId) return claim;
    }
    return null;
  }

  void startWatching() {
    _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    _notify();

    _subscription = repository.watchClaims(userId).listen(
      (items) {
        _claims = List<MedicalClaim>.from(items)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        _errorMessage = null;
        _notify();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = 'Could not load medical claims.';
        _notify();
      },
    );
  }

  Future<void> refresh() async {
    startWatching();
  }

  void setViewFilter(MedicalClaimsViewFilter filter) {
    _viewFilter = filter;
    _selectedStatusFilter = null;
    _notify();
  }

  void setStatusFilter(MedicalClaimStatus? status) {
    _selectedStatusFilter = status;
    _viewFilter = MedicalClaimsViewFilter.all;
    _notify();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _notify();
  }

  Future<Uint8List?> downloadClaimDocument(MedicalBillDocument document) async {
    try {
      return await repository.downloadDocument(
        storagePath: document.storagePath,
        localPreviewPath: document.localPreviewPath,
      );
    } catch (_) {
      _errorMessage = 'Failed to download document.';
      _notify();
      return null;
    }
  }

  Future<bool> deleteClaimDocument({
    required String claimId,
    required MedicalBillDocument document,
  }) async {
    try {
      await repository.deleteDocument(
        claimId: claimId,
        documentId: document.documentId,
        storagePath: document.storagePath,
      );
      final existing = findClaim(claimId);
      if (existing != null) {
        final remaining = existing.documents
            .where((d) => d.documentId != document.documentId)
            .toList();
        _claims = [
          for (final c in _claims)
            if (c.claimId == claimId) c.copyWith(documents: remaining) else c,
        ];
        _notify();
      }
      return true;
    } catch (_) {
      _errorMessage = 'Failed to remove document.';
      _notify();
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
    _notify();

    try {
      final activeUser = _getCurrentUserId(userId ?? this.userId);
      final draft = MedicalClaim(
        claimId: '',
        userId: activeUser,
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

      final saved = await repository.submitClaim(
        draft,
        localBillFilePath: localBillFilePath,
        attachments: attachments,
      );

      _claims = [
        saved,
        for (final c in _claims)
          if (c.claimId != saved.claimId) c,
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _isSubmitting = false;
      _notify();
      return saved;
    } catch (error) {
      _isSubmitting = false;
      _errorMessage = 'Failed to submit medical claim: $error';
      _notify();
      return null;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
