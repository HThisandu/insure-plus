import 'claim_document.dart';

enum ClaimStatus {
  submitted('Submitted', 'Submitted'),
  underReview('UnderReview', 'Under review'),
  moreInfoRequired('MoreInfoRequired', 'More info required'),
  approved('Approved', 'Approved'),
  rejected('Rejected', 'Rejected');

  const ClaimStatus(this.value, this.label);

  final String value;
  final String label;
}

class Claim {
  Claim({
    required this.claimId,
    required this.userId,
    required this.policyId,
    required this.claimType,
    required this.claimAmount,
    required this.description,
    required this.status,
    required List<ClaimDocument> documents,
    required this.createdAt,
  }) : documents = List.unmodifiable(documents);

  final String claimId;
  final String userId;
  final String policyId;
  final String claimType;
  final num claimAmount;
  final String description;
  final ClaimStatus status;
  final List<ClaimDocument> documents;
  final DateTime createdAt;

  Claim withStatus(ClaimStatus status) => Claim(
    claimId: claimId,
    userId: userId,
    policyId: policyId,
    claimType: claimType,
    claimAmount: claimAmount,
    description: description,
    status: status,
    documents: documents,
    createdAt: createdAt,
  );
}
