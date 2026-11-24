import 'package:flutter/material.dart';

import '../model/policy.dart';
import '../services/policy_service.dart';
import '../widgets/policy_card.dart';
import 'policy_details_screen.dart';

class PolicyListScreen extends StatelessWidget {
  const PolicyListScreen({super.key});

  static const Color primaryColor = Color(0xFF123B65);

  static final PolicyService policyService = PolicyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'My Policies',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
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
                    size: 55,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No Policies Available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: policies.length,
            itemBuilder: (context, index) {
              final policy = policies[index];

              return Padding(
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
              );
            },
          );
        },
      ),
    );
  }
}
