import 'package:flutter/foundation.dart';

import '../models/claim.dart';

class ClaimService extends ChangeNotifier {
  ClaimService(Iterable<Claim> claims)
    : _claims = {for (final claim in claims) claim.claimId: claim};

  final Map<String, Claim> _claims;

  List<Claim> get claims =>
      _claims.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Claim? findClaim(String claimId) => _claims[claimId];

  int countByStatus(ClaimStatus status) =>
      _claims.values.where((claim) => claim.status == status).length;

  List<ClaimStatus> reviewOptions(ClaimStatus status) => switch (status) {
    ClaimStatus.submitted ||
    ClaimStatus.moreInfoRequired => const [ClaimStatus.underReview],
    ClaimStatus.underReview => const [
      ClaimStatus.moreInfoRequired,
      ClaimStatus.approved,
      ClaimStatus.rejected,
    ],
    ClaimStatus.approved || ClaimStatus.rejected => const [],
  };

  bool updateStatus(String claimId, ClaimStatus expected, ClaimStatus next) {
    final claim = findClaim(claimId);
    if (claim == null ||
        claim.status != expected ||
        !reviewOptions(expected).contains(next)) {
      return false;
    }
    _claims[claimId] = claim.withStatus(next);
    notifyListeners();
    return true;
  }
}
