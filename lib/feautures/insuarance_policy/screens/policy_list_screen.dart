import 'package:flutter/material.dart';

import '../model/policy.dart';
import '../services/policy_service.dart';
import '../widgets/policy_status_badge.dart';
import 'policy_details_screen.dart';

class PolicyListScreen extends StatelessWidget {
  const PolicyListScreen({super.key});

  static const Color primaryColor = Color(0xFF153E66);
  static const Color backgroundColor = Color(0xFFF4F7FC);

  static final PolicyService policyService = PolicyService();

  Widget summaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primaryColor, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'My Policies',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: primaryColor),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: StreamBuilder<List<Policy>>(
        stream: policyService.getPolicies(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading policies:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final policies = snapshot.data ?? [];

          if (policies.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No Policies Available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Your insurance policies will appear here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final activeCount = policies
              .where((p) => p.status.toLowerCase() == 'active')
              .length;

          final pendingCount = policies
              .where((p) => p.status.toLowerCase() == 'pending')
              .length;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // HEADER
              const Text(
                'Your protection, all in one place',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey),
              ),

              const SizedBox(height: 18),

              // SUMMARY CARDS
              Row(
                children: [
                  summaryCard(
                    'Total Policies',
                    '${policies.length}',
                    Icons.shield_outlined,
                  ),
                  const SizedBox(width: 12),
                  summaryCard(
                    'Active',
                    '$activeCount',
                    Icons.verified_outlined,
                  ),
                  const SizedBox(width: 12),
                  summaryCard(
                    'Pending',
                    '$pendingCount',
                    Icons.pending_actions,
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // SECTION TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Policies',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    '${policies.length} policies',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // POLICY LIST
              ...policies.map((policy) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PolicyDetailsScreen(policy: policy),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF2FF),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: primaryColor,
                                  size: 23,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      policy.policyName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      policy.category,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              PolicyStatusBadge(status: policy.status),
                            ],
                          ),

                          const SizedBox(height: 16),

                          const Divider(height: 1),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              const Icon(
                                Icons.confirmation_number_outlined,
                                size: 15,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  policy.policyId,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                              const Text(
                                'View details',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
