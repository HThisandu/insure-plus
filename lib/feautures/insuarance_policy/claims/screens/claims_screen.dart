import 'package:flutter/material.dart';

import '../models/claim.dart';
import '../services/claim_service.dart';
import '../widgets/claim_card.dart';
import 'claim_details_screen.dart';
import 'submit_claim_screen.dart';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  final ClaimService _claimService = ClaimService();

  List<Claim> get claims => _claimService.getClaims();

  @override
  Widget build(BuildContext context) {
    final allClaims = claims;

    final pendingCount = allClaims
        .where((claim) => claim.status.toLowerCase() == 'pending')
        .length;

    final approvedCount = allClaims
        .where((claim) => claim.status.toLowerCase() == 'approved')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'My Claims',
          style: TextStyle(
            color: Color(0xFF123B65),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Summary Cards

            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Total Claims',
                    allClaims.length.toString(),
                    Icons.description,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    'Pending',
                    pendingCount.toString(),
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    'Approved',
                    approvedCount.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Submit Claim Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubmitClaimScreen(),
                    ),
                  );

                  setState(() {});
                },
                icon: const Icon(Icons.add),
                label: const Text('Submit New Claim'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF123B65),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Recent Claims',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123B65),
              ),
            ),

            const SizedBox(height: 14),

            if (allClaims.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.folder_open, size: 50, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No Claims Found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Your submitted claims will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ...allClaims.map(
                (claim) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClaimCard(
                    claim: claim,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClaimDetailsScreen(claim: claim),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
