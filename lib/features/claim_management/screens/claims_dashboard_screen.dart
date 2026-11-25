import 'package:flutter/material.dart';

import '../widgets/claim_scaffold.dart';

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
    return ClaimScaffold(
      title: 'Claim Management',
      body: SafeArea(
        child: ListenableBuilder(
          listenable: service,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                color: ClaimScaffold.navy,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Claims dashboard',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
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
