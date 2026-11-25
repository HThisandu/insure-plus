import 'package:flutter/material.dart';

import '../widgets/claim_scaffold.dart';

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

  bool _saving = false;
  bool _saveFailed = false;

  Future<void> _save() async {
    final nextStatus = _nextStatus;
    if (nextStatus == null || _saving) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      final saved = await widget.service.updateStatus(
        widget.claim.claimId,
        widget.claim.status,
        nextStatus,
      );
      if (!mounted) return;
      if (saved && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop(nextStatus.label);
      } else {
        setState(() => _stale = true);
      }
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClaimScaffold(
      title: 'Review claim',
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
              onChanged: _stale || _saving
                  ? null
                  : (status) => setState(() => _nextStatus = status),
            ),
            if (_saveFailed)
              const Text(
                'Unable to save status. Check your access and connection, then retry.',
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
              onPressed: _nextStatus == null || _stale || _saving
                  ? null
                  : _save,
              child: Text(_saving ? 'Saving…' : 'Save status'),
            ),
          ],
        ),
      ),
    );
  }
}
