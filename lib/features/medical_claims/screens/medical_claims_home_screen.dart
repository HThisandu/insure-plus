import 'package:flutter/material.dart';

import '../models/medical_claim.dart';
import '../models/medical_claim_status.dart';
import '../services/medical_claim_service.dart';
import '../widgets/medical_claim_card.dart';
import '../widgets/medical_status_badge.dart';
import 'medical_claim_details_screen.dart';
import 'submit_medical_claim_screen.dart';

class MedicalClaimsHomeScreen extends StatefulWidget {
  const MedicalClaimsHomeScreen({
    super.key,
    required this.service,
    this.defaultPolicyId = 'MEDICAL-001',
    this.onScanBillWithOcr,
  });

  final MedicalClaimService service;
  final String defaultPolicyId;
  final OcrBillScannerCallback? onScanBillWithOcr;

  @override
  State<MedicalClaimsHomeScreen> createState() =>
      _MedicalClaimsHomeScreenState();
}

class _MedicalClaimsHomeScreenState extends State<MedicalClaimsHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openSubmitForm() async {
    final created = await Navigator.of(context).push<MedicalClaim>(
      MaterialPageRoute(
        builder: (_) => SubmitMedicalClaimScreen(
          service: widget.service,
          defaultPolicyId: widget.defaultPolicyId,
          onScanBillWithOcr: widget.onScanBillWithOcr,
        ),
      ),
    );
    if (!mounted || created == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Medical claim ${created.claimId} submitted successfully.',
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _openClaimDetails(created.claimId),
        ),
      ),
    );
  }

  void _openClaimDetails(String claimId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MedicalClaimDetailsScreen(
          service: widget.service,
          claimId: claimId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Claims'),
        actions: [
          IconButton(
            tooltip: 'Refresh claims',
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.service.refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSubmitForm,
        icon: const Icon(Icons.add),
        label: const Text('New Claim'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.service,
          builder: (context, _) {
            final claims = widget.service.filteredClaims;
            final allCount = widget.service.claims.length;

            if (widget.service.isLoading && allCount == 0) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: widget.service.refresh,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      _SummaryCard(service: widget.service),
                      const SizedBox(height: 16),
                      if (widget.service.errorMessage != null) ...[
                        Card(
                          color: colors.errorContainer,
                          child: ListTile(
                            leading: Icon(
                              Icons.error_outline,
                              color: colors.onErrorContainer,
                            ),
                            title: Text(
                              widget.service.errorMessage!,
                              style: TextStyle(color: colors.onErrorContainer),
                            ),
                            trailing: TextButton(
                              onPressed: widget.service.refresh,
                              child: const Text('Retry'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: _searchController,
                        onChanged: widget.service.setSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Search hospital, patient, or claim ID',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: widget.service.searchQuery.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    widget.service.setSearchQuery('');
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text('All ($allCount)'),
                                selected:
                                    widget.service.selectedStatusFilter == null,
                                onSelected: (_) =>
                                    widget.service.setStatusFilter(null),
                              ),
                            ),
                            for (final status in MedicalClaimStatus.values)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(
                                    '${status.label} (${widget.service.countByStatus(status)})',
                                  ),
                                  selected:
                                      widget.service.selectedStatusFilter ==
                                      status,
                                  onSelected: (selected) =>
                                      widget.service.setStatusFilter(
                                        selected ? status : null,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (claims.isEmpty)
                        _EmptyClaimsState(
                          hasFilters:
                              widget.service.selectedStatusFilter != null ||
                              widget.service.searchQuery.trim().isNotEmpty,
                          onClearFilters: () {
                            _searchController.clear();
                            widget.service.setSearchQuery('');
                            widget.service.setStatusFilter(null);
                          },
                          onSubmitNew: _openSubmitForm,
                        )
                      else
                        for (final claim in claims)
                          MedicalClaimCard(
                            claim: claim,
                            onTap: () => _openClaimDetails(claim.claimId),
                          ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.service});

  final MedicalClaimService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Medical Claims Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _SummaryMetric(
                  label: 'Total Claims',
                  value: '${service.claims.length}',
                  color: colors.onPrimaryContainer,
                ),
                _SummaryMetric(
                  label: 'Total Claimed',
                  value: formatLkr(service.totalClaimedAmount),
                  color: colors.onPrimaryContainer,
                ),
                _SummaryMetric(
                  label: 'Approved',
                  value: formatLkr(service.approvedAmount),
                  color: colors.onPrimaryContainer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyClaimsState extends StatelessWidget {
  const _EmptyClaimsState({
    required this.hasFilters,
    required this.onClearFilters,
    required this.onSubmitNew,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onSubmitNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              hasFilters
                  ? Icons.filter_list_off_outlined
                  : Icons.medical_information_outlined,
              size: 48,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'No matching medical claims'
                  : 'No medical claims submitted yet',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Try adjusting your status filter or search query.'
                  : 'Submit a new medical claim to track reimbursement progress.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (hasFilters)
              OutlinedButton(
                onPressed: onClearFilters,
                child: const Text('Clear filters'),
              )
            else
              FilledButton.icon(
                onPressed: onSubmitNew,
                icon: const Icon(Icons.add),
                label: const Text('Submit Medical Claim'),
              ),
          ],
        ),
      ),
    );
  }
}
