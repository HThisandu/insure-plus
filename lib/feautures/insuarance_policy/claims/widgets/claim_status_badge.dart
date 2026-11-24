import 'package:flutter/material.dart';

class ClaimStatusBadge extends StatelessWidget {
  final String status;

  const ClaimStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color statusColor;

    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;

      case 'rejected':
        statusColor = Colors.red;
        break;

      case 'under review':
        statusColor = Colors.orange;
        break;

      default:
        statusColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
