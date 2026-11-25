import 'package:flutter/material.dart';

import '../models/claim.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ClaimStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      ClaimStatus.submitted => (
        const Color(0xFFFFF1D7),
        const Color(0xFF704B0C),
      ),
      ClaimStatus.underReview => (
        const Color(0xFFE5EEFF),
        const Color(0xFF214F91),
      ),
      ClaimStatus.moreInfoRequired => (
        const Color(0xFFFFEADB),
        const Color(0xFF813D18),
      ),
      ClaimStatus.approved => (
        const Color(0xFFE0F4E9),
        const Color(0xFF17613D),
      ),
      ClaimStatus.rejected => (
        const Color(0xFFFFE8EC),
        const Color(0xFF93263C),
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          status.label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
