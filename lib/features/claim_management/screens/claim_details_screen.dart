import 'package:flutter/material.dart';

import '../services/claim_service.dart';
import '../widgets/status_badge.dart';
import 'claim_review_screen.dart';

class ClaimDetailsScreen extends StatelessWidget {
  const ClaimDetailsScreen({
    super.key,
    required this.service,
    required this.claimId,
  });

  final ClaimService service;
  final String claimId;

  @override
  Widget build(BuildContext context) {
    final dates = MaterialLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Claim details')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: service,
          builder: (context, _) {
            final claim = service.findClaim(claimId);
            if (claim == null) {
              return const Center(child: Text('Claim unavailable.'));
            }
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  claim.claimId,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(status: claim.status),
                ),
                ListTile(
                  title: const Text('Type'),
                  subtitle: Text(claim.claimType),
                ),
                ListTile(
                  title: const Text('Policy'),
                  subtitle: Text(claim.policyId),
                ),
                ListTile(
                  title: const Text('Policyholder ID'),
                  subtitle: Text(claim.userId),
                ),
                ListTile(
                  title: const Text('Claim amount'),
                  subtitle: Text('LKR ${claim.claimAmount.toStringAsFixed(2)}'),
                ),
                ListTile(
                  title: const Text('Submitted on'),
                  subtitle: Text(
                    dates.formatMediumDate(claim.createdAt.toLocal()),
                  ),
                ),
                ListTile(
                  title: const Text('Description'),
                  subtitle: Text(claim.description),
                ),
                const Divider(),
                Text(
                  'Documents',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (claim.documents.isEmpty)
                  const Text('No documents attached.'),
                for (final document in claim.documents)
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(document.fileName),
                    subtitle: Text(
                      '${document.documentType} · ${dates.formatMediumDate(document.uploadedAt.toLocal())}',
                    ),
                  ),
                if (service.reviewOptions(claim.status).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final status = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) =>
                              ClaimReviewScreen(service: service, claim: claim),
                        ),
                      );
                      if (context.mounted && status != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Claim status updated to ${status.toLowerCase()}.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Review claim'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
