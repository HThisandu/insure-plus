import 'package:flutter/material.dart';

import '../models/medical_claim_status.dart';
import 'medical_status_badge.dart';

class MedicalClaimStatusTimeline extends StatelessWidget {
  const MedicalClaimStatusTimeline({
    super.key,
    required this.status,
    this.submittedAt,
    this.inline = false,
  });

  final MedicalClaimStatus status;
  final DateTime? submittedAt;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(status, submittedAt);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!inline) ...[
          const Text(
            'Claim Progress',
            style: TextStyle(
              color: MedicalClaimsColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
        ],
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(
            step: steps[i],
            isLast: i == steps.length - 1,
          ),
      ],
    );

    if (inline) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MedicalClaimsColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MedicalClaimsColors.border),
      ),
      child: content,
    );
  }

  List<_TimelineStep> _buildSteps(
    MedicalClaimStatus current,
    DateTime? createdAt,
  ) {
    final submittedPrefix = createdAt != null
        ? '${formatFigmaDate(createdAt, includeYear: false)} · '
        : '';

    final isSubmittedCompleted = current != MedicalClaimStatus.submitted;
    final isReviewActive =
        current == MedicalClaimStatus.underReview ||
        current == MedicalClaimStatus.moreInfoRequired;
    final isReviewCompleted =
        current == MedicalClaimStatus.approved ||
        current == MedicalClaimStatus.rejected;

    final decisionStep = switch (current) {
      MedicalClaimStatus.approved => const _TimelineStep(
        title: 'Approved',
        subtitle: 'Your medical claim has been approved for settlement',
        state: _StepState.completed,
      ),
      MedicalClaimStatus.rejected => const _TimelineStep(
        title: 'Rejected',
        subtitle: 'Not covered under your medical policy terms',
        state: _StepState.error,
      ),
      MedicalClaimStatus.moreInfoRequired => const _TimelineStep(
        title: 'More info required',
        subtitle: 'Additional medical bills or reports requested',
        state: _StepState.warning,
      ),
      _ => const _TimelineStep(
        title: 'Decision',
        subtitle: 'We\'ll notify you when it\'s ready',
        state: _StepState.upcoming,
      ),
    };

    return [
      _TimelineStep(
        title: 'Submitted',
        subtitle: '${submittedPrefix}We received your claim',
        state: isSubmittedCompleted
            ? _StepState.completed
            : _StepState.completed,
      ),
      _TimelineStep(
        title: 'Under review',
        subtitle: isReviewCompleted
            ? 'Verification completed by operations'
            : (isReviewActive
                  ? 'Our team is reviewing'
                  : 'Review will begin shortly'),
        state: isReviewCompleted
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
  const _TimelineRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (circleBg, iconColor, titleColor, icon) = switch (step.state) {
      _StepState.completed => (
        MedicalClaimsColors.successBg,
        MedicalClaimsColors.successFg,
        MedicalClaimsColors.successFg,
        Icons.check_rounded,
      ),
      _StepState.active => (
        MedicalClaimsColors.softBlue,
        MedicalClaimsColors.accentBlue,
        MedicalClaimsColors.accentBlue,
        Icons.access_time_rounded,
      ),
      _StepState.warning => (
        MedicalClaimsColors.infoReqBg,
        MedicalClaimsColors.infoReqFg,
        MedicalClaimsColors.infoReqFg,
        Icons.priority_high_rounded,
      ),
      _StepState.error => (
        MedicalClaimsColors.rejectedBg,
        MedicalClaimsColors.rejectedFg,
        MedicalClaimsColors.rejectedFg,
        Icons.close_rounded,
      ),
      _StepState.upcoming => (
        const Color(0xFFF1F5F9),
        MedicalClaimsColors.textSecondary,
        MedicalClaimsColors.textSecondary,
        Icons.info_outline_rounded,
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
                  color: circleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: step.state == _StepState.completed
                        ? MedicalClaimsColors.successBg
                        : MedicalClaimsColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    step.subtitle,
                    style: const TextStyle(
                      color: MedicalClaimsColors.textSecondary,
                      fontSize: 12,
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
