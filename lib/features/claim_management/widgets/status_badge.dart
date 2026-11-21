import 'package:flutter/material.dart';

import '../models/claim.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ClaimStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      ClaimStatus.submitted => (
        colors.surfaceContainerHighest,
        colors.onSurface,
      ),
      ClaimStatus.underReview => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      ClaimStatus.moreInfoRequired => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      ClaimStatus.approved => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      ClaimStatus.rejected => (colors.errorContainer, colors.onErrorContainer),
    };
    return Chip(
      label: Text(status.label, style: TextStyle(color: foreground)),
      backgroundColor: background,
      side: BorderSide.none,
    );
  }
}
