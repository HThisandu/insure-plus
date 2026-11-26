import 'package:flutter/material.dart';

import '../models/medical_claim_status.dart';

class MedicalStatusBadge extends StatelessWidget {
  const MedicalStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final MedicalClaimStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (status) {
      MedicalClaimStatus.submitted => (
        colors.surfaceContainerHighest,
        colors.onSurface,
        Icons.schedule_outlined,
      ),
      MedicalClaimStatus.underReview => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.manage_search_outlined,
      ),
      MedicalClaimStatus.moreInfoRequired => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        Icons.info_outline,
      ),
      MedicalClaimStatus.approved => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.check_circle_outline,
      ),
      MedicalClaimStatus.rejected => (
        colors.errorContainer,
        colors.onErrorContainer,
        Icons.cancel_outlined,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String formatLkr(num amount) {
  final isNegative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0];
  final fraction = parts[1];

  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final reverseIndex = whole.length - i;
    if (i > 0 && reverseIndex % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(whole[i]);
  }

  return '${isNegative ? '-' : ''}LKR ${buffer.toString()}.$fraction';
}
