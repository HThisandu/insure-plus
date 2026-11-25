import 'package:flutter/material.dart';

import 'common/services/firebase_app_service.dart';
import 'common/services/supabase_app_service.dart';
import 'common/theme/insurecare_theme.dart';
import 'modules/motor_claims/motor_claims.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase provides the signed-in identity. Supabase stores claims and files.
  await FirebaseAppService.initialize();
  await SupabaseAppService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insure Plus',
      debugShowCheckedModeBanner: false,
      theme: InsureCareTheme.light,
      home: const MyHomePage(title: 'Insure Plus'),
      routes: {
        '/motor-claims': (context) => const MotorClaimsDashboardScreen(),
      },
    );
  }
}

/// Insure Plus landing screen styled from the supplied Figma home dashboard.
/// The summary is populated only from real Motor Claims records.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedTab = 0;

  void _openClaims() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MotorClaimsDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claims = MotorClaimService();

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: claims,
          builder: (context, _) {
            final stats = claims.getStatistics();
            final inProgress =
                (stats['submitted'] ?? 0) +
                (stats['underReview'] ?? 0) +
                (stats['moreInfoRequired'] ?? 0);
            final closed = (stats['approved'] ?? 0) + (stats['rejected'] ?? 0);

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hello, Welcome Back!',
                                  style: TextStyle(
                                    color: InsureCareTheme.muted,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: InsureCareTheme.navy,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 44,
                            width: 44,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {},
                              tooltip: 'Notifications',
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: InsureCareTheme.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: InsureCareTheme.navy,
                          borderRadius: BorderRadius.circular(22),
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
                                  "You're in safe hands.",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'A little planning. A lot of peace of mind.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.76),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _OverviewValue(
                                  value: (stats['total'] ?? 0)
                                      .toString()
                                      .padLeft(2, '0'),
                                  label: 'Total\nClaims',
                                ),
                                _OverviewValue(
                                  value: inProgress.toString().padLeft(2, '0'),
                                  label: 'In progress',
                                ),
                                _OverviewValue(
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
                            child: _QuickAction(
                              icon: Icons.description_outlined,
                              label: 'View Claims',
                              onTap: _openClaims,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.add_rounded,
                              label: 'Make a Claim',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SubmitMotorClaimScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.track_changes_rounded,
                              label: 'Track Status',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TrackMotorClaimScreen(),
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
                            onPressed: _openClaims,
                            child: const Text('See all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (claims.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(26),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (claims.lastError != null)
                        _NoticeCard(
                          icon: Icons.cloud_off_outlined,
                          title: 'Claims are not available right now',
                          subtitle:
                              'Check the Supabase setup and try loading again.',
                          actionLabel: 'Try again',
                          onAction: claims.refreshClaims,
                        )
                      else if (claims.claims.isEmpty)
                        _NoticeCard(
                          icon: Icons.shield_outlined,
                          title: 'Your claims will appear here',
                          subtitle: 'When you submit a motor claim, you can follow its progress from this page.',
                          actionLabel: 'Make a claim',
                          onAction: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SubmitMotorClaimScreen(),
                            ),
                          ),
                        )
                      else
                        ...claims.claims
                            .take(3)
                            .map(
                              (claim) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _openClaims,
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          Container(
                                            height: 42,
                                            width: 42,
                                            decoration: BoxDecoration(
                                              color: InsureCareTheme.paleBlue,
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                            child: const Icon(
                                              Icons.directions_car_outlined,
                                              color: InsureCareTheme.iconBlue,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  claim.vehicleDisplayName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: InsureCareTheme.text,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${claim.claimId} · ${claim.status.label}',
                                                  style: const TextStyle(
                                                    color:
                                                        InsureCareTheme.muted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            color: InsureCareTheme.muted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: InsureCareTheme.paleBlue,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'HERE WHEN YOU NEED US',
                                    style: TextStyle(
                                      color: InsureCareTheme.iconBlue,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  const Text(
                                    'Your journey matters.',
                                    style: TextStyle(
                                      color: InsureCareTheme.navy,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Keep your vehicle claim details and updates together in one place.',
                                    style: TextStyle(
                                      color: InsureCareTheme.muted,
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: _openClaims,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(44, 36),
                                      foregroundColor: InsureCareTheme.navy,
                                    ),
                                    child: const Text('Explore claims  ›'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.directions_car_filled_outlined,
                              size: 48,
                              color: InsureCareTheme.iconBlue,
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
          if (index == 1) _openClaims();
          if (index == 0) setState(() => _selectedTab = 0);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Claims',
          ),
        ],
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({required this.value, required this.label});

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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
          child: Column(
            children: [
              Icon(icon, color: InsureCareTheme.iconBlue, size: 23),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: InsureCareTheme.navy,
                  fontSize: 10,
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

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: InsureCareTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: InsureCareTheme.iconBlue, size: 23),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: InsureCareTheme.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: InsureCareTheme.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
