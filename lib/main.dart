import 'package:flutter/material.dart';
import 'features/authentication/screens/login_screen.dart';

void main() {
  runApp(const InsurePlusApp());
}

class InsurePlusApp extends StatelessWidget {
  const InsurePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insure Plus',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}