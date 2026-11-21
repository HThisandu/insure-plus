import 'package:flutter/material.dart';

import '../models/claim.dart';
import '../services/claim_service.dart';
import '../widgets/status_badge.dart';

class ClaimReviewScreen extends StatefulWidget {
  const ClaimReviewScreen({
    super.key,
    required this.service,
    required this.claim,
  });

  final ClaimService service;
  final Claim claim;

  @override
  State<ClaimReviewScreen> createState() => _ClaimReviewScreenState();
}

class _ClaimReviewScreenState extends State<ClaimReviewScreen> {
  ClaimStatus? _nextStatus;
  bool _stale = false;

  void _save() {
    final nextStatus = _nextStatus;
    if (nextStatus == null) return;
    if (widget.service.updateStatus(
      widget.claim.claimId,
      widget.claim.status,
      nextStatus,
    )) {
      Navigator.of(context).pop(nextStatus.label);
    } else {
      setState(() => _stale = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review claim')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              widget.claim.claimId,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(status: widget.claim.status),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ClaimStatus>(
              decoration: const InputDecoration(
                labelText: 'New status',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final status in widget.service.reviewOptions(
                  widget.claim.status,
                ))
                  DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: _stale
                  ? null
                  : (status) => setState(() => _nextStatus = status),
            ),
            if (_stale)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'This claim changed. Go back to see its current status.',
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _nextStatus == null || _stale ? null : _save,
              child: const Text('Save status'),
            ),
          ],
        ),
      ),
    );
  }
}
