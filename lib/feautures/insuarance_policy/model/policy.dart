class Policy {
  final String policyId;
  final String policyName;
  final String category;
  final String description;
  final double premium;
  final double totalCoverage;
  final double usedAmount;
  final String status;
  final DateTime startDate;
  final DateTime expiryDate;
  final List<String> features;

  const Policy({
    required this.policyId,
    required this.policyName,
    required this.category,
    required this.description,
    required this.premium,
    required this.totalCoverage,
    required this.usedAmount,
    required this.status,
    required this.startDate,
    required this.expiryDate,
    required this.features,
  });

  double get remainingBalance {
    return (totalCoverage - usedAmount).clamp(0.0, totalCoverage);
  }

  double get coveragePercentage {
    if (totalCoverage <= 0) return 0;
    return (usedAmount / totalCoverage).clamp(0.0, 1.0);
  }

  bool get isActive => status == 'Active';

  factory Policy.fromMap(Map<String, dynamic> map, String id) {
    return Policy(
      policyId: id,
      policyName: map['policyName'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      premium: (map['premium'] as num?)?.toDouble() ?? 0,
      totalCoverage: (map['totalCoverage'] as num?)?.toDouble() ?? 0,
      usedAmount: (map['usedAmount'] as num?)?.toDouble() ?? 0,
      status: map['status'] ?? 'Pending',
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime(2000),
      expiryDate: DateTime.tryParse(map['expiryDate'] ?? '') ?? DateTime(2000),
      features: List<String>.from(map['features'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'policyName': policyName,
      'category': category,
      'description': description,
      'premium': premium,
      'totalCoverage': totalCoverage,
      'usedAmount': usedAmount,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'features': features,
    };
  }
}
