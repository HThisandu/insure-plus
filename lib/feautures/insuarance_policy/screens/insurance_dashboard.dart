import 'package:flutter/material.dart';

import '../model/policy.dart';
import '../services/policy_service.dart';
import '../widgets/policy_card.dart';
import 'policy_details_screen.dart';

class InsuranceDashboard extends StatelessWidget {
  const InsuranceDashboard({super.key});

  static const Color primaryColor = Color(0xFF123B65);
  static const Color backgroundColor = Color(0xFFF5F7FB);

  static final PolicyService policyService = PolicyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Insure-Plus',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: primaryColor),
          ),
        ],
      ),

      body: SafeArea(
        child: StreamBuilder<List<Policy>>(
          stream: policyService.getPolicies(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error loading policies:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final List<Policy> policies = snapshot.data ?? [];

            final activePolicies = policies
                .where((policy) => policy.isActive)
                .length;

            final totalCoverage = policies.fold<double>(
              0,
              (sum, policy) => sum + policy.totalCoverage,
            );

            final remainingBalance = policies.fold<double>(
              0,
              (sum, policy) => sum + policy.remainingBalance,
            );

            final remainingPercentage = totalCoverage > 0
                ? (remainingBalance / totalCoverage) * 100
                : 0.0;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Hello, Policyholder 👋',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Manage your insurance policies in one place.',
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 24),

                // Overview Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Coverage',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'LKR ${totalCoverage.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _overviewItem(
                            'Active Policies',
                            activePolicies.toString().padLeft(2, '0'),
                          ),
                          _overviewItem(
                            'Remaining',
                            '${remainingPercentage.toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Insurance Categories
                const Text(
                  'Insurance Categories',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.25,
                  children: [
                    _categoryCard(
                      Icons.directions_car,
                      'Motor Insurance',
                      Colors.blue,
                    ),
                    _categoryCard(
                      Icons.local_hospital,
                      'Medical Insurance',
                      Colors.green,
                    ),
                    _categoryCard(
                      Icons.favorite,
                      'Life Insurance',
                      Colors.redAccent,
                    ),
                    _categoryCard(
                      Icons.flight,
                      'Travel Insurance',
                      Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // My Policies
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Policies',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),

                    Text(
                      '${policies.length} Policies',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (policies.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 45,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No Policies Available',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Your insurance policies will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  ...policies.map(
                    (policy) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PolicyCard(
                        title: policy.policyName,
                        subtitle: '${policy.policyId} • ${policy.status}',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PolicyDetailsScreen(policy: policy),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _overviewItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _categoryCard(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
