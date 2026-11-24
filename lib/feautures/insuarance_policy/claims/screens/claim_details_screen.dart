import 'package:flutter/material.dart';

import '../models/claim.dart';
import '../widgets/claim_status_badge.dart';

class ClaimDetailsScreen extends StatelessWidget {
  final Claim claim;

  const ClaimDetailsScreen({super.key, required this.claim});

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
        title: const Text('Claim Details'),
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
                      claim.claimType,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    ClaimStatusBadge(status: claim.status),

                    const Divider(height: 30),

                    detailRow('Claim ID', claim.claimId),
                    detailRow('Policy ID', claim.policyId),
                    detailRow(
                      'Claim Amount',
                      'LKR ${claim.claimAmount.toStringAsFixed(2)}',
                    ),
                    detailRow(
                      'Submitted Date',
                      formatDate(claim.submittedDate),
                    ),
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
                child: Text(claim.description),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Supporting Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            if (claim.documents.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.folder_open),
                  title: Text('No documents uploaded'),
                ),
              )
            else
              ...claim.documents.map(
                (document) => Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.insert_drive_file,
                      color: primaryColor,
                    ),
                    title: Text(document),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
