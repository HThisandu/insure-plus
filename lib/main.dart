import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabasePublishableKey,
    accessToken: () async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return null;
      }

      return await user.getIdToken();
    },
  );

  runApp(const InsurePlusApp());
}

class InsurePlusApp extends StatelessWidget {
  const InsurePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Insure-Plus',
      home: Scaffold(
        appBar: AppBar(title: const Text('Insure-Plus')),
        body: const Center(child: Text('Insure-Plus Backend Ready!')),
      ),
    );
  }
}
