import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';

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
        await AuthService().registerUser(
          fullName: 'Test User',
          email: 'testuser001@example.com',
          password: 'Test@123456',
          phoneNumber: '0771234567',
        );

        debugPrint('Registration Successful!');
      } catch (e) {
        debugPrint('Registration Error: $e');
      }
    },
    child: const Text('Test Registration'),
  ),
),

      ),
    );
  }
}
