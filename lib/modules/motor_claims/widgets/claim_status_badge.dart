import 'package:flutter/material.dart';
import '../../../common/models/claim_status.dart';

/// Reusable badge widget to display the status of a claim.
/// Beginner-friendly implementation using color and icon from [ClaimStatusExtension].
class ClaimStatusBadge extends StatelessWidget {
  final ClaimStatus status;
  final bool isCompact;

  const ClaimStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.0 : 12.0,
        vertical: isCompact ? 4.0 : 6.0,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: status.color.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: isCompact ? 14.0 : 16.0,
            color: status.color,
          ),
          const SizedBox(width: 6.0),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 11.0 : 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
