import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_claim_service.dart';
import 'claims_dashboard_screen.dart';

/// Mount inside the authenticated staff area after Firebase initialization.
class FirestoreClaimsScreen extends StatefulWidget {
  const FirestoreClaimsScreen({super.key, required this.firestore});

  final FirebaseFirestore firestore;

  @override
  State<FirestoreClaimsScreen> createState() => _FirestoreClaimsScreenState();
}

class _FirestoreClaimsScreenState extends State<FirestoreClaimsScreen> {
  FirestoreClaimService? _service;
  late Future<FirestoreClaimService> _load = _loadClaims();

  Future<FirestoreClaimService> _loadClaims() async {
    final service = await FirestoreClaimService.load(widget.firestore);
    if (mounted) {
      _service = service;
    } else {
      service.dispose();
    }
    return service;
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirestoreClaimService>(
      future: _load,
      builder: (context, snapshot) {
        final service = snapshot.data;
        if (service != null) return ClaimsDashboardScreen(service: service);
        return Scaffold(
          appBar: AppBar(title: const Text('Claim Management')),
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Unable to load claims. Check your staff access and connection.',
                      ),
                      TextButton(
                        onPressed: () => setState(() => _load = _loadClaims()),
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
