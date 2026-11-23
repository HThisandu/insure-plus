import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'services/claims_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const InsurePlusApp());
}

class InsurePlusApp extends StatelessWidget {
  const InsurePlusApp({super.key});

  Future<void> testFirestoreConnection() async {
    await FirebaseFirestore.instance
        .collection('connection_tests')
        .doc('test001')
        .set({
          'message': 'Firestore Connected',
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Insure-Plus',
      home: Scaffold(
        appBar: AppBar(title: const Text('Insure-Plus')),

        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              try {
                // Login
                await AuthService().loginUser(
                  email: 'testuser001@example.com',
                  password: 'Test@123456',
                );

                debugPrint('Login Successful!');

                // Submit Claim
                final claimId = await ClaimsService().submitClaim(
                  policyId: 'TEST_POLICY_001',
                  claimType: 'Medical',
                  claimAmount: 25000,
                  description: 'Hospital treatment',
                );

                debugPrint('Claim Submitted Successfully!');
                debugPrint('Claim ID: $claimId');
              } catch (e) {
                debugPrint('Error: $e');
              }
            },
            child: const Text('Test Submit Claim'),
          ),
        ),
      ),
    );
  }
}
