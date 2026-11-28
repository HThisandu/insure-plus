import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'common/services/firebase_app_service.dart';
import 'common/services/supabase_app_service.dart';
import 'common/theme/insurecare_theme.dart';
import 'features/authentication/screens/account_screen.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/medical_claims/medical_claims.dart';
import 'feautures/insuarance_policy/screens/insurance_dashboard.dart';
import 'modules/motor_claims/motor_claims.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseAppService.initialize();
  await SupabaseAppService.initialize();

  runApp(const MyApp());
}

typedef InsurePlusApp = MyApp;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insure Plus',
      debugShowCheckedModeBanner: false,
      theme: InsureCareTheme.light,
      home: const AuthGate(),
      routes: {
        '/motor-claims': (context) => const MotorClaimsDashboardScreen(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _session = FirebaseAuth.instance.idTokenChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Unable to check your session. Please restart the app.',
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) return const LoginScreen();

        return MyHomePage(
          title: 'Insure Plus',
          onAccount: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AccountScreen(user: user, token: user.getIdTokenResult()),
              ),
            );
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.onAccount});

  final String title;
  final VoidCallback? onAccount;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedTab = 0;
  InMemoryMedicalClaimRepository? _demoMedicalRepo;
  late final MedicalClaimService _medicalClaimService = _createMedicalService();

  MedicalClaimService _createMedicalService() {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      return MedicalClaimService.live();
    }
    _demoMedicalRepo = InMemoryMedicalClaimRepository();
    return MedicalClaimService(repository: _demoMedicalRepo!);
  }

  @override
  void dispose() {
    _medicalClaimService.dispose();
    _demoMedicalRepo?.dispose();
    super.dispose();
  }

  void _openMotorClaims() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MotorClaimsDashboardScreen(),
      ),
    );
  }

  void _openMedicalClaims() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MedicalClaimsHomeScreen(service: _medicalClaimService),
      ),
    );
  }

  void _openPolicies() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const InsuranceDashboard()),
    );
  }

  Widget _buildHomeBody() {
    final claims = MotorClaimService();

    return ListenableBuilder(
      listenable: Listenable.merge([claims, _medicalClaimService]),
      builder: (context, _) {
        final stats = claims.getStatistics();
        final motorInProgress =
            (stats['submitted'] ?? 0) +
            (stats['underReview'] ?? 0) +
            (stats['moreInfoRequired'] ?? 0);
        final motorClosed = (stats['approved'] ?? 0) + (stats['rejected'] ?? 0);

        final totalClaims =
            (stats['total'] ?? 0) + _medicalClaimService.claims.length;
        final inProgress =
            motorInProgress + _medicalClaimService.inProgressCount;
        final closed = motorClosed + _medicalClaimService.closedCount;

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
                          onPressed: widget.onAccount,
                          tooltip: 'My account',
                          icon: const Icon(
                            Icons.account_circle_outlined,
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
                              value: totalClaims.toString().padLeft(2, '0'),
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
                          icon: Icons.shield_outlined,
                          label: 'My Policies',
                          onTap: _openPolicies,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.medical_services_outlined,
                          label: 'Medical Claims',
                          onTap: _openMedicalClaims,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.directions_car_outlined,
                          label: 'Motor Claims',
                          onTap: _openMotorClaims,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.description_outlined,
                          label: 'View Claims',
                          onTap: _openMedicalClaims,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.add_rounded,
                          label: 'Make a Claim',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => SubmitMedicalClaimScreen(
                                service: _medicalClaimService,
                                userId: _medicalClaimService.userId,
                              ),
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
                            MaterialPageRoute<void>(
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
                        onPressed: _openMedicalClaims,
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_medicalClaimService.claims.isEmpty &&
                      claims.claims.isEmpty)
                    _NoticeCard(
                      icon: Icons.shield_outlined,
                      title: 'Your claims will appear here',
                      subtitle:
                          'Submit a medical or motor claim to follow its progress from this page.',
                      actionLabel: 'Make a claim',
                      onAction: _openMedicalClaims,
                    )
                  else ...[
                    for (final med in _medicalClaimService.claims.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _openMedicalClaims,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    height: 42,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: InsureCareTheme.paleBlue,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.local_hospital_outlined,
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
                                          med.hospitalName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: InsureCareTheme.text,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${med.claimId} · ${med.status.label}',
                                          style: const TextStyle(
                                            color: InsureCareTheme.muted,
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
                    for (final claim in claims.claims.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _openMotorClaims,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    height: 42,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: InsureCareTheme.paleBlue,
                                      borderRadius: BorderRadius.circular(13),
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
                                          overflow: TextOverflow.ellipsis,
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
                                            color: InsureCareTheme.muted,
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
                  ],
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildHomeBody(),
      const InsuranceDashboard(),
      MedicalClaimsHomeScreen(service: _medicalClaimService),
      const MotorClaimsDashboardScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedTab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() => _selectedTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Policies',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services_rounded),
            label: 'Medical',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car_rounded),
            label: 'Motor',
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
