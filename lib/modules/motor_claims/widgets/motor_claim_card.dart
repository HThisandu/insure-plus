import 'package:flutter/material.dart';

import '../../../common/theme/insurecare_theme.dart';
import '../models/motor_claim.dart';
import 'claim_status_badge.dart';

/// Compact recent-activity card using the InsureCare white-card style.
class MotorClaimCard extends StatelessWidget {
  final MotorClaim claim;
  final VoidCallback? onTap;

  const MotorClaimCard({super.key, required this.claim, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: InsureCareTheme.border, width: 0.7),
          ),
          child: Row(
            children: [
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  color: InsureCareTheme.paleBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.directions_car_outlined,
                  color: InsureCareTheme.iconBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${claim.vehicleYear} ${claim.vehicleMake} ${claim.vehicleModel}'
                              .trim()
                              .isEmpty
                          ? 'Motor claim'
                          : '${claim.vehicleYear} ${claim.vehicleMake} ${claim.vehicleModel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: InsureCareTheme.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      claim.claimId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: InsureCareTheme.muted,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      claim.vehicleRegistrationNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: InsureCareTheme.muted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          claim.formattedAmount,
                          style: const TextStyle(
                            color: InsureCareTheme.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '·',
                          style: TextStyle(color: InsureCareTheme.muted),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            claim.formattedIncidentDate,
                            style: const TextStyle(
                              color: InsureCareTheme.muted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClaimStatusBadge(status: claim.status, isCompact: true),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: InsureCareTheme.muted,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
