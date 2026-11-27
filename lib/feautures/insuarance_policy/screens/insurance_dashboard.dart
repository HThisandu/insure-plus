import 'package:flutter/material.dart';

import '../model/policy.dart';
import '../services/policy_service.dart';
import 'policy_details_screen.dart';

class InsuranceDashboard extends StatelessWidget {
  const InsuranceDashboard({super.key});

  static const Color primaryColor = Color(0xFF153E66);
  static const Color backgroundColor = Color(0xFFF4F7FC);

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
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 8),
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

            final policies = snapshot.data ?? [];

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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Welcome back! Manage your insurance with ease.',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 14),
                ),

                const SizedBox(height: 25),

                // Coverage overview
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF153E66), Color(0xFF24669B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: Colors.white70,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'TOTAL COVERAGE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'LKR ${totalCoverage.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _overviewItem(
                              'Active Policies',
                              activePolicies.toString().padLeft(2, '0'),
                              Icons.verified_user_outlined,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 45,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _overviewItem(
                              'Remaining Balance',
                              '${remainingPercentage.toStringAsFixed(1)}%',
                              Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                _sectionTitle('Insurance Categories'),
                const SizedBox(height: 15),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.35,
                  children: [
                    _categoryCard(
                      Icons.directions_car_rounded,
                      'Motor Insurance',
                      const Color(0xFF3478C7),
                    ),
                    _categoryCard(
                      Icons.local_hospital_rounded,
                      'Medical Insurance',
                      const Color(0xFF27A477),
                    ),
                    _categoryCard(
                      Icons.favorite_rounded,
                      'Life Insurance',
                      const Color(0xFFE16C78),
                    ),
                    _categoryCard(
                      Icons.flight_rounded,
                      'Travel Insurance',
                      const Color(0xFFE6A044),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionTitle('My Policies'),
                    Text(
                      '${policies.length} Policies',
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                if (policies.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 45,
                          color: Colors.blueGrey,
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
                      padding: const EdgeInsets.only(bottom: 13),
                      child: _policyCard(policy, context),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    );
  }

  Widget _overviewItem(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _categoryCard(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyCard(Policy policy, BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PolicyDetailsScreen(policy: policy),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1F9),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: primaryColor,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    policy.policyName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${policy.policyId} • ${policy.status}',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.blueGrey,
            ),
          ],
        ),
      ),
    );
  }
}
