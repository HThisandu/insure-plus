import 'package:flutter/material.dart';

import '../../../common/theme/insurecare_theme.dart';
import '../services/motor_claim_service.dart';
import '../widgets/motor_claim_card.dart';
import 'motor_claims_list_screen.dart';
import 'submit_motor_claim_screen.dart';
import 'track_motor_claim_screen.dart';
import 'motor_claim_details_screen.dart';

/// Motor Claims overview using the InsureCare Figma visual language.
class MotorClaimsDashboardScreen extends StatelessWidget {
  const MotorClaimsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final claimService = MotorClaimService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Motor claims'),
        actions: [
          IconButton(
            tooltip: 'Track a claim',
            icon: const Icon(Icons.track_changes_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TrackMotorClaimScreen()),
            ),
          ),
          IconButton(
            tooltip: 'All claims',
            icon: const Icon(Icons.list_alt_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MotorClaimsListScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListenableBuilder(
        listenable: claimService,
        builder: (context, _) {
          if (claimService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (claimService.lastError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 42,
                      color: InsureCareTheme.iconBlue,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load claims from Supabase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: InsureCareTheme.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check the Supabase setup and your connection, then try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: InsureCareTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: claimService.refreshClaims,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final stats = claimService.getStatistics();
          final active =
              (stats['submitted'] ?? 0) +
              (stats['underReview'] ?? 0) +
              (stats['moreInfoRequired'] ?? 0);
          final closed = (stats['approved'] ?? 0) + (stats['rejected'] ?? 0);
          final recentClaims = claimService.claims.take(3).toList();

          return RefreshIndicator(
            onRefresh: claimService.refreshClaims,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
              children: [
                const Text(
                  "You're in safe hands.",
                  style: TextStyle(
                    color: InsureCareTheme.navy,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'A little planning. A lot of peace of mind.',
                  style: TextStyle(color: InsureCareTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: InsureCareTheme.navy,
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFFBFD7F5),
                            size: 22,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Motor claims overview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _OverviewMetric(
                            value: (stats['total'] ?? 0).toString().padLeft(
                              2,
                              '0',
                            ),
                            label: 'Total\nclaims',
                          ),
                          _OverviewMetric(
                            value: active.toString().padLeft(2, '0'),
                            label: 'In progress',
                          ),
                          _OverviewMetric(
                            value: closed.toString().padLeft(2, '0'),
                            label: 'Closed',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'What would you like to do?',
                  style: TextStyle(
                    color: InsureCareTheme.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DashboardAction(
                        icon: Icons.add_rounded,
                        label: 'Make a claim',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubmitMotorClaimScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DashboardAction(
                        icon: Icons.list_alt_rounded,
                        label: 'View claims',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MotorClaimsListScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent activity',
                      style: TextStyle(
                        color: InsureCareTheme.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MotorClaimsListScreen(),
                        ),
                      ),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (recentClaims.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: InsureCareTheme.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          color: InsureCareTheme.iconBlue,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No motor claims yet',
                          style: TextStyle(
                            color: InsureCareTheme.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your submitted claims and their updates will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: InsureCareTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...recentClaims.map(
                    (claim) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MotorClaimCard(
                        claim: claim,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MotorClaimDetailsScreen(claimId: claim.claimId),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: InsureCareTheme.paleBlue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HERE WHEN YOU NEED US',
                              style: TextStyle(
                                color: InsureCareTheme.iconBlue,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Need an update?',
                              style: TextStyle(
                                color: InsureCareTheme.navy,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'View your claim status and required next steps in one place.',
                              style: TextStyle(
                                color: InsureCareTheme.muted,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.support_agent_outlined,
                        color: InsureCareTheme.iconBlue,
                        size: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: InsureCareTheme.iconBlue, size: 23),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: InsureCareTheme.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
