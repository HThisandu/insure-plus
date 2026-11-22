import 'package:flutter/material.dart';

import '../models/medical_claim_status.dart';

class MedicalClaimStatusTimeline extends StatelessWidget {
  const MedicalClaimStatusTimeline({super.key, required this.status});

  final MedicalClaimStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final steps = _buildSteps(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Claim Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < steps.length; i++)
              _TimelineRow(
                step: steps[i],
                isLast: i == steps.length - 1,
                colors: colors,
              ),
          ],
        ),
      ),
    );
  }

  List<_TimelineStep> _buildSteps(MedicalClaimStatus current) {
    final isSubmittedDone = current != MedicalClaimStatus.submitted;
    final isReviewActive =
        current == MedicalClaimStatus.underReview ||
        current == MedicalClaimStatus.moreInfoRequired;
    final isReviewDone =
        current == MedicalClaimStatus.approved ||
        current == MedicalClaimStatus.rejected;

    final decisionStep = switch (current) {
      MedicalClaimStatus.approved => const _TimelineStep(
        title: 'Approved',
        subtitle: 'Your medical claim has been approved for settlement.',
        state: _StepState.completed,
      ),
      MedicalClaimStatus.rejected => const _TimelineStep(
        title: 'Rejected',
        subtitle: 'This claim could not be approved under policy terms.',
        state: _StepState.error,
      ),
      MedicalClaimStatus.moreInfoRequired => const _TimelineStep(
        title: 'More info required',
        subtitle: 'Operations requested additional supporting medical documents.',
        state: _StepState.warning,
      ),
      _ => const _TimelineStep(
        title: 'Final decision',
        subtitle: 'Pending claims team approval and payout sanction.',
        state: _StepState.upcoming,
      ),
    };

    return [
      _TimelineStep(
        title: 'Submitted',
        subtitle: 'Medical claim and bill details received.',
        state: isSubmittedDone ? _StepState.completed : _StepState.active,
      ),
      _TimelineStep(
        title: 'Under review',
        subtitle: 'Claims operations team is verifying hospital & bill records.',
        state: isReviewDone
            ? _StepState.completed
            : (isReviewActive ? _StepState.active : _StepState.upcoming),
      ),
      decisionStep,
    ];
  }
}

enum _StepState { completed, active, warning, error, upcoming }

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.state,
  });

  final String title;
  final String subtitle;
  final _StepState state;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isLast,
    required this.colors,
  });

  final _TimelineStep step;
  final bool isLast;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (dotBg, dotFg, icon) = switch (step.state) {
      _StepState.completed => (
        colors.primary,
        colors.onPrimary,
        Icons.check,
      ),
      _StepState.active => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.hourglass_top_rounded,
      ),
      _StepState.warning => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        Icons.priority_high_rounded,
      ),
      _StepState.error => (
        colors.error,
        colors.onError,
        Icons.close_rounded,
      ),
      _StepState.upcoming => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
        Icons.circle_outlined,
      ),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: dotBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: dotFg),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: step.state == _StepState.completed
                        ? colors.primary
                        : colors.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: step.state == _StepState.upcoming
                          ? colors.onSurfaceVariant
                          : colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
