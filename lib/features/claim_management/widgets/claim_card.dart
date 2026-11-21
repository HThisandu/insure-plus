import 'package:flutter/material.dart';

import '../models/claim.dart';
import 'status_badge.dart';

class ClaimCard extends StatelessWidget {
  const ClaimCard({super.key, required this.claim, required this.onTap});

  final Claim claim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(claim.claimId),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${claim.claimType} · LKR ${claim.claimAmount.toStringAsFixed(2)}',
            ),
            StatusBadge(status: claim.status),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
