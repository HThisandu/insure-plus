import 'package:flutter/material.dart';
import '../../../common/models/claim_status.dart';
import '../services/motor_claim_service.dart';
import '../widgets/claim_summary_card.dart';
import '../widgets/motor_claim_card.dart';
import 'motor_claims_list_screen.dart';
import 'submit_motor_claim_screen.dart';
import 'track_motor_claim_screen.dart';
import 'motor_claim_details_screen.dart';

/// Main Dashboard Screen for Member 04 – Motor Claims Module.
/// Provides overview metrics for the 5 allowed statuses:
/// Submitted, UnderReview, MoreInfoRequired, Approved, Rejected.
class MotorClaimsDashboardScreen extends StatelessWidget {
  const MotorClaimsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final claimService = MotorClaimService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Motor Claims Portal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.track_changes_rounded),
            tooltip: 'Track Claim',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrackMotorClaimScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'All Claims',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MotorClaimsListScreen()),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: claimService,
        builder: (context, _) {
          final stats = claimService.getStatistics();
          final recentClaims = claimService.claims.take(3).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: const BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Member 04 • Motor Claims',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cloud_done_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  claimService.firebaseService.isFirebaseAvailable
                                      ? 'Firebase Active'
                                      : 'Firebase Ready',
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Vehicle Insurance Claims',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lodge, inspect, track, and manage all your motor damage claims.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Statistics Grid covering the allowed statuses
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Claims Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClaimSummaryCard(
                              title: 'Total Claims',
                              count: stats['total'] ?? 0,
                              icon: Icons.assignment_rounded,
                              color: Colors.indigo,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MotorClaimsListScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClaimSummaryCard(
                              title: 'Submitted',
                              count: stats['submitted'] ?? 0,
                              icon: Icons.hourglass_top_rounded,
                              color: Colors.orange,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MotorClaimsListScreen(
                                      initialStatus: ClaimStatus.submitted,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClaimSummaryCard(
                              title: 'Under Review',
                              count: stats['underReview'] ?? 0,
                              icon: Icons.search_rounded,
                              color: Colors.blue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MotorClaimsListScreen(
                                      initialStatus: ClaimStatus.underReview,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClaimSummaryCard(
                              title: 'More Info Needed',
                              count: stats['moreInfoRequired'] ?? 0,
                              icon: Icons.help_outline_rounded,
                              color: Colors.deepPurple,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MotorClaimsListScreen(
                                      initialStatus: ClaimStatus.moreInfoRequired,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClaimSummaryCard(
                              title: 'Approved',
                              count: stats['approved'] ?? 0,
                              icon: Icons.check_circle_outline_rounded,
                              color: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MotorClaimsListScreen(
                                      initialStatus: ClaimStatus.approved,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClaimSummaryCard(
                              title: 'Rejected',
                              count: stats['rejected'] ?? 0,
                              icon: Icons.cancel_outlined,
                              color: Colors.red,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MotorClaimsListScreen(
                                      initialStatus: ClaimStatus.rejected,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SubmitMotorClaimScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('File New Claim'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TrackMotorClaimScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.track_changes_rounded),
                          label: const Text('Track Status'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.indigo,
                            side: const BorderSide(color: Colors.indigo, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Roadside Assistance Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade100, Colors.amber.shade50],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.amber.shade700,
                          child: const Icon(Icons.support_agent_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '24/7 Roadside Assistance',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Accident or vehicle breakdown? Call 1800-INSURE for instant towing & mobile surveyor.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.brown.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Recent Claims Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Motor Claims',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MotorClaimsListScreen(),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),

                if (recentClaims.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('No claims submitted yet.'),
                    ),
                  )
                else
                  ...recentClaims.map(
                    (claim) => MotorClaimCard(
                      claim: claim,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MotorClaimDetailsScreen(claimId: claim.claimId),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
