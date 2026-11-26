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
  bool _showSearch = false;

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
          userId: widget.service.userId,
          initialPolicyId: widget.defaultPolicyId,
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
    return Theme(
      data: buildMedicalClaimsFigmaTheme(context),
      child: Builder(
        builder: (themedContext) {
          return Scaffold(
            backgroundColor: MedicalClaimsColors.canvas,
            body: SafeArea(
              child: ListenableBuilder(
                listenable: widget.service,
                builder: (context, _) {
                  final claims = widget.service.filteredClaims;
                  final totalCount = widget.service.claims.length;

                  if (widget.service.isLoading && totalCount == 0) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return RefreshIndicator(
                    onRefresh: widget.service.refresh,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your claims, in view.',
                                        style: TextStyle(
                                          color: MedicalClaimsColors.navy,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Follow every update, from start to resolution.',
                                        style: TextStyle(
                                          color:
                                              MedicalClaimsColors.textSecondary,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: _showSearch
                                      ? 'Hide search'
                                      : 'Search claims',
                                  onPressed: () {
                                    setState(() {
                                      _showSearch = !_showSearch;
                                      if (!_showSearch) {
                                        _searchController.clear();
                                        widget.service.setSearchQuery('');
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    _showSearch
                                        ? Icons.search_off_rounded
                                        : Icons.search_rounded,
                                    color: MedicalClaimsColors.navy,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Refresh claims',
                                  onPressed: widget.service.refresh,
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    color: MedicalClaimsColors.navy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _openSubmitForm,
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: const Text('Submit a new claim'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                            if (_showSearch) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _searchController,
                                onChanged: widget.service.setSearchQuery,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search hospital, patient, or claim ID',
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon:
                                      widget.service.searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear_rounded,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            widget.service.setSearchQuery('');
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            _FilterPillsBar(service: widget.service),
                            const SizedBox(height: 16),
                            if (widget.service.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: MedicalClaimsColors.rejectedBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: MedicalClaimsColors.rejectedFg,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        widget.service.errorMessage!,
                                        style: const TextStyle(
                                          color: MedicalClaimsColors.rejectedFg,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: widget.service.refresh,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (claims.isEmpty)
                              _EmptyClaimsCard(
                                hasFilters:
                                    widget.service.selectedStatusFilter !=
                                        null ||
                                    widget.service.viewFilter !=
                                        MedicalClaimsViewFilter.all ||
                                    widget.service.searchQuery
                                        .trim()
                                        .isNotEmpty,
                                onClearFilters: () {
                                  _searchController.clear();
                                  widget.service.setSearchQuery('');
                                  widget.service.setStatusFilter(null);
                                  widget.service.setViewFilter(
                                    MedicalClaimsViewFilter.all,
                                  );
                                },
                                onSubmitNew: _openSubmitForm,
                              )
                            else
                              for (var i = 0; i < claims.length; i++)
                                MedicalClaimCard(
                                  claim: claims[i],
                                  featured:
                                      i == 0 &&
                                      MedicalClaimService.isInProgressStatus(
                                        claims[i].status,
                                      ),
                                  onTap: () =>
                                      _openClaimDetails(claims[i].claimId),
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
        },
      ),
    );
  }
}

class _FilterPillsBar extends StatelessWidget {
  const _FilterPillsBar({required this.service});

  final MedicalClaimService service;

  @override
  Widget build(BuildContext context) {
    final isAllSelected =
        service.selectedStatusFilter == null &&
        service.viewFilter == MedicalClaimsViewFilter.all;
    final isInProgressSelected =
        service.selectedStatusFilter == null &&
        service.viewFilter == MedicalClaimsViewFilter.inProgress;
    final isClosedSelected =
        service.selectedStatusFilter == null &&
        service.viewFilter == MedicalClaimsViewFilter.closed;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FigmaFilterPill(
            label: 'All claims (${service.claims.length})',
            selected: isAllSelected,
            onTap: () => service.setViewFilter(MedicalClaimsViewFilter.all),
          ),
          _FigmaFilterPill(
            label: 'In progress (${service.inProgressCount})',
            selected: isInProgressSelected,
            onTap: () =>
                service.setViewFilter(MedicalClaimsViewFilter.inProgress),
          ),
          _FigmaFilterPill(
            label: 'Closed (${service.closedCount})',
            selected: isClosedSelected,
            onTap: () => service.setViewFilter(MedicalClaimsViewFilter.closed),
          ),
          for (final status in MedicalClaimStatus.values)
            _FigmaFilterPill(
              label: '${status.label} (${service.countByStatus(status)})',
              selected: service.selectedStatusFilter == status,
              onTap: () => service.setStatusFilter(
                service.selectedStatusFilter == status ? null : status,
              ),
            ),
        ],
      ),
    );
  }
}

class _FigmaFilterPill extends StatelessWidget {
  const _FigmaFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? MedicalClaimsColors.navy : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? MedicalClaimsColors.navy
                : MedicalClaimsColors.border,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : MedicalClaimsColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyClaimsCard extends StatelessWidget {
  const _EmptyClaimsCard({
    required this.hasFilters,
    required this.onClearFilters,
    required this.onSubmitNew,
  });

  final bool hasFilters;
  final VoidCallback onClearFilters;
  final VoidCallback onSubmitNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MedicalClaimsColors.border),
      ),
      child: Column(
        children: [
          Icon(
            hasFilters
                ? Icons.filter_list_off_rounded
                : Icons.medical_information_outlined,
            size: 44,
            color: MedicalClaimsColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? 'No matching medical claims'
                : 'No medical claims submitted yet',
            style: const TextStyle(
              color: MedicalClaimsColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? 'Try switching status filters or clearing your search.'
                : 'Submit your hospital bill or medical report to start tracking reimbursement.',
            style: const TextStyle(
              color: MedicalClaimsColors.textSecondary,
              fontSize: 13,
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
              icon: const Icon(Icons.add_rounded),
              label: const Text('Submit a new claim'),
            ),
        ],
      ),
    );
  }
}
