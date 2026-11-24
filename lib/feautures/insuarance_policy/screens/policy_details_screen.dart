import 'package:flutter/material.dart';

import '../model/policy.dart';
import '../widgets/policy_status_badge.dart';

class PolicyDetailsScreen extends StatelessWidget {
  final Policy policy;

  const PolicyDetailsScreen({super.key, required this.policy});

  static const Color primaryColor = Color(0xFF123B65);

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Policy Details'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.policyName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(policy.category),

                    const SizedBox(height: 12),

                    PolicyStatusBadge(status: policy.status),

                    const Divider(height: 30),

                    detailRow('Policy ID', policy.policyId),
                    detailRow(
                      'Premium',
                      'Rs. ${policy.premium.toStringAsFixed(2)}',
                    ),
                    detailRow(
                      'Total Coverage',
                      'Rs. ${policy.totalCoverage.toStringAsFixed(2)}',
                    ),
                    detailRow(
                      'Used Amount',
                      'Rs. ${policy.usedAmount.toStringAsFixed(2)}',
                    ),
                    detailRow(
                      'Remaining Balance',
                      'Rs. ${policy.remainingBalance.toStringAsFixed(2)}',
                    ),
                    detailRow('Start Date', formatDate(policy.startDate)),
                    detailRow('Expiry Date', formatDate(policy.expiryDate)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(policy.description),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Policy Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...policy.features.map(
              (feature) => Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(feature),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
