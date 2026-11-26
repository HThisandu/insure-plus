import 'package:flutter/material.dart';

import '../models/medical_claim.dart';
import '../models/medical_claim_status.dart';
import 'medical_claim_status_timeline.dart';
import 'medical_status_badge.dart';

class MedicalClaimCard extends StatelessWidget {
  const MedicalClaimCard({
    super.key,
    required this.claim,
    required this.onTap,
    this.featured = false,
  });

  final MedicalClaim claim;
  final VoidCallback onTap;
  final bool featured;

  String _statusCaption(MedicalClaimStatus status) => switch (status) {
    MedicalClaimStatus.submitted => 'Received. Review will begin shortly.',
    MedicalClaimStatus.underReview =>
      'Our operations team is reviewing your hospital bills.',
    MedicalClaimStatus.moreInfoRequired =>
      'Additional medical bills or reports requested.',
    MedicalClaimStatus.approved => 'Approved for settlement under your policy.',
    MedicalClaimStatus.rejected => 'Not covered under your policy.',
  };

  @override
  Widget build(BuildContext context) {
    final dateLabel = formatFigmaDate(claim.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: MedicalClaimsColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: MedicalClaimsColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: featured
                ? _FeaturedCardBody(claim: claim, dateLabel: dateLabel)
                : _CompactCardBody(
                    claim: claim,
                    dateLabel: dateLabel,
                    caption: _statusCaption(claim.status),
                  ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCardBody extends StatelessWidget {
  const _FeaturedCardBody({required this.claim, required this.dateLabel});

  final MedicalClaim claim;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              claim.hospitalName,
              style: const TextStyle(
                color: MedicalClaimsColors.navy,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            MedicalStatusBadge(status: claim.status, compact: true),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${claim.claimId} · ${claim.treatmentType} · ${claim.patientName}',
          style: const TextStyle(
            color: MedicalClaimsColors.textSecondary,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatLkr(claim.claimAmount),
              style: const TextStyle(
                color: MedicalClaimsColors.navy,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              dateLabel,
              style: const TextStyle(
                color: MedicalClaimsColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: MedicalClaimsColors.border),
        const SizedBox(height: 16),
        MedicalClaimStatusTimeline(
          status: claim.status,
          submittedAt: claim.createdAt,
          inline: true,
        ),
      ],
    );
  }
}

class _CompactCardBody extends StatelessWidget {
  const _CompactCardBody({
    required this.claim,
    required this.dateLabel,
    required this.caption,
  });

  final MedicalClaim claim;
  final String dateLabel;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                claim.hospitalName,
                style: const TextStyle(
                  color: MedicalClaimsColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            MedicalStatusBadge(status: claim.status, compact: true),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${claim.claimId} · $dateLabel · ${claim.treatmentType}',
          style: const TextStyle(
            color: MedicalClaimsColors.textSecondary,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                formatLkr(claim.claimAmount),
                style: const TextStyle(
                  color: MedicalClaimsColors.navy,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: MedicalClaimsColors.navy,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: const TextStyle(
            color: MedicalClaimsColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
