import 'package:flutter/material.dart';
import '../models/motor_claim.dart';
import 'claim_status_badge.dart';

/// Reusable card displaying an overview of a single motor claim.
/// Shows claim ID, vehicle information, incident date, amount, and status badge.
class MotorClaimCard extends StatelessWidget {
  final MotorClaim claim;
  final VoidCallback? onTap;

  const MotorClaimCard({
    super.key,
    required this.claim,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Claim ID & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car_rounded, color: Colors.indigo, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        claim.claimId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  ClaimStatusBadge(status: claim.status, isCompact: true),
                ],
              ),
              const Divider(height: 20),

              // Vehicle & Claimant Info
              Text(
                '${claim.vehicleYear} ${claim.vehicleMake} ${claim.vehicleModel}',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      claim.vehicleRegistrationNumber,
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•  ${claim.incidentType}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom Row: Date, Photos count & Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        claim.formattedIncidentDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (claim.accidentPhotos.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.photo_library_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 3),
                        Text(
                          '${claim.accidentPhotos.length}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    claim.formattedAmount,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
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
