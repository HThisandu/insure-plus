import 'package:flutter/material.dart';

import '../models/claim.dart';
import '../services/claim_service.dart';
import 'claims_list_screen.dart';

class ClaimsDashboardScreen extends StatelessWidget {
  const ClaimsDashboardScreen({super.key, required this.service});

  final ClaimService service;

  void _openClaims(BuildContext context, [ClaimStatus? status]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ClaimsListScreen(service: service, initialStatus: status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Claim Management')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: service,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Claims dashboard',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openClaims(context),
                icon: const Icon(Icons.list_alt),
                label: Text('All claims (${service.claims.length})'),
              ),
              const SizedBox(height: 16),
              for (final status in ClaimStatus.values)
                Card(
                  child: ListTile(
                    title: Text(status.label),
                    trailing: Text('${service.countByStatus(status)}'),
                    onTap: () => _openClaims(context, status),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
