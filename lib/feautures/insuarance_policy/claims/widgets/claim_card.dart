import 'package:flutter/material.dart';

import '../models/claim.dart';
import 'claim_status_badge.dart';

class ClaimCard extends StatelessWidget {
  final Claim claim;
  final VoidCallback? onTap;

  const ClaimCard({super.key, required this.claim, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAF1F8),
          child: Icon(Icons.description_outlined, color: Color(0xFF123B65)),
        ),
        title: Text(
          claim.claimType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Claim ID: ${claim.claimId}'),
              const SizedBox(height: 5),
              Text('Amount: LKR ${claim.claimAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              ClaimStatusBadge(status: claim.status),
            ],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
