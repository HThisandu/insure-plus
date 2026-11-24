import '../models/claim.dart';

class ClaimService {
  ClaimService._internal();

  static final ClaimService _instance = ClaimService._internal();

  factory ClaimService() => _instance;

  final List<Claim> _claims = [];

  List<Claim> getClaims() {
    return List.unmodifiable(_claims);
  }

  Claim? getClaimById(String claimId) {
    for (final claim in _claims) {
      if (claim.claimId == claimId) {
        return claim;
      }
    }
    return null;
  }

  List<Claim> getClaimsByPolicyId(String policyId) {
    return _claims.where((claim) => claim.policyId == policyId).toList();
  }

  void addClaim(Claim claim) {
    _claims.add(claim);
  }

  void removeClaim(String claimId) {
    _claims.removeWhere((claim) => claim.claimId == claimId);
  }

  void updateClaimStatus(String claimId, String newStatus) {
    final index = _claims.indexWhere((claim) => claim.claimId == claimId);

    if (index == -1) return;

    final oldClaim = _claims[index];

    _claims[index] = Claim(
      claimId: oldClaim.claimId,
      policyId: oldClaim.policyId,
      claimType: oldClaim.claimType,
      description: oldClaim.description,
      claimAmount: oldClaim.claimAmount,
      status: newStatus,
      submittedDate: oldClaim.submittedDate,
      documents: oldClaim.documents,
    );
  }
}
