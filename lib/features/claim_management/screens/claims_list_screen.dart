import 'package:flutter/material.dart';

import '../widgets/claim_scaffold.dart';

import '../models/claim.dart';
import '../services/claim_service.dart';
import '../widgets/claim_card.dart';
import 'claim_details_screen.dart';

class ClaimsListScreen extends StatefulWidget {
  const ClaimsListScreen({
    super.key,
    required this.service,
    this.initialStatus,
  });

  final ClaimService service;
  final ClaimStatus? initialStatus;

  @override
  State<ClaimsListScreen> createState() => _ClaimsListScreenState();
}

class _ClaimsListScreenState extends State<ClaimsListScreen> {
  late ClaimStatus? _status = widget.initialStatus;

  @override
  Widget build(BuildContext context) {
    return ClaimScaffold(
      title: 'Claims',
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.service,
          builder: (context, _) {
            final claims = widget.service.claims
                .where((claim) => _status == null || claim.status == _status)
                .toList();
            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: claims.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<ClaimStatus>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(child: Text('All statuses')),
                          for (final status in ClaimStatus.values)
                            DropdownMenuItem(
                              value: status,
                              child: Text(status.label),
                            ),
                        ],
                        onChanged: (status) => setState(() => _status = status),
                      ),
                      const SizedBox(height: 16),
                      if (claims.isEmpty)
                        const Text('No claims for this status.'),
                    ],
                  );
                }
                final claim = claims[index - 1];
                return ClaimCard(
                  claim: claim,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ClaimDetailsScreen(
                        service: widget.service,
                        claimId: claim.claimId,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
