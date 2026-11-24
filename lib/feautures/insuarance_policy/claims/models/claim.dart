class Claim {
  final String claimId;
  final String policyId;
  final String claimType;
  final String description;
  final double claimAmount;
  final String status;
  final DateTime submittedDate;
  final List<String> documents;

  const Claim({
    required this.claimId,
    required this.policyId,
    required this.claimType,
    required this.description,
    required this.claimAmount,
    required this.status,
    required this.submittedDate,
    required this.documents,
  });

  bool get isApproved => status == 'Approved';

  factory Claim.fromMap(Map<String, dynamic> map, String id) {
    return Claim(
      claimId: id,
      policyId: map['policyId'] ?? '',
      claimType: map['claimType'] ?? '',
      description: map['description'] ?? '',
      claimAmount: (map['claimAmount'] as num?)?.toDouble() ?? 0,
      status: map['status'] ?? 'Pending',
      submittedDate:
          DateTime.tryParse(map['submittedDate'] ?? '') ?? DateTime(2000),
      documents: List<String>.from(map['documents'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'policyId': policyId,
      'claimType': claimType,
      'description': description,
      'claimAmount': claimAmount,
      'status': status,
      'submittedDate': submittedDate.toIso8601String(),
      'documents': documents,
    };
  }
}
