import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app/app_router.dart';
import 'app/app_theme.dart';

void main() => runApp(const InsurePlusApp());

class InsurePlusApp extends StatefulWidget {
  const InsurePlusApp({super.key});

  @override
  State<InsurePlusApp> createState() => _InsurePlusAppState();
}

class _InsurePlusAppState extends State<InsurePlusApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Insure Plus',
      theme: appTheme,
      routerConfig: _router,
    );
  }
}
