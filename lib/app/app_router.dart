import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/claims/claims_screen.dart';
import '../shared/widgets/module_placeholder.dart';
import 'app_shell.dart';

class AppRoutes {
  static const dashboard = '/';
  static const policies = '/policies';
  static const claims = '/claims';
  static const motorClaims = 'motor-claims';
  static const medicalClaims = 'medical-claims';
  static const profile = '/profile';

  // Reserved until role-based access is integrated.
  static const staffClaimManagement = '/staff/claims';
}

GoRouter createAppRouter() {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const ModulePlaceholder(
                  title: 'Customer dashboard',
                  description: 'Your insurance overview will appear here.',
                  icon: Icons.dashboard_outlined,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.policies,
                builder: (context, state) => const ModulePlaceholder(
                  title: 'Insurance policies',
                  description:
                      'Your policies, coverage and balances will appear here.',
                  icon: Icons.policy_outlined,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.claims,
                builder: (context, state) => ClaimsScreen(
                  openMotorClaims: () =>
                      context.pushNamed(AppRoutes.motorClaims),
                  openMedicalClaims: () =>
                      context.pushNamed(AppRoutes.medicalClaims),
                ),
                routes: [
                  GoRoute(
                    parentNavigatorKey: rootNavigatorKey,
                    path: 'motor',
                    name: AppRoutes.motorClaims,
                    builder: (context, state) => Scaffold(
                      appBar: AppBar(title: const Text('Motor Claims')),
                      body: const ModulePlaceholder(
                        title: 'Motor claim submission',
                        description:
                            'The motor claim form and status will appear here.',
                        icon: Icons.directions_car_outlined,
                      ),
                    ),
                  ),
                  GoRoute(
                    parentNavigatorKey: rootNavigatorKey,
                    path: 'medical',
                    name: AppRoutes.medicalClaims,
                    builder: (context, state) => Scaffold(
                      appBar: AppBar(title: const Text('Medical Claims')),
                      body: const ModulePlaceholder(
                        title: 'Medical claim submission',
                        description: 'The medical claim form and status will appear here.',
                        icon: Icons.medical_services_outlined,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ModulePlaceholder(
                  title: 'Your profile',
                  description: 'Your account details will appear here.',
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
