import 'package:flutter/material.dart';

import '../../../common/models/claim_status.dart';
import '../../../common/theme/insurecare_theme.dart';
import '../models/motor_claim.dart';
import '../models/claim_milestone.dart';
import '../services/motor_claim_service.dart';
import 'submit_motor_claim_screen.dart';
import 'motor_claim_details_screen.dart';

/// User-facing claims list styled after the supplied Figma "Your claims, in view" screen.
class MotorClaimsListScreen extends StatefulWidget {
  final ClaimStatus? initialStatus;

  const MotorClaimsListScreen({super.key, this.initialStatus});

  @override
  State<MotorClaimsListScreen> createState() => _MotorClaimsListScreenState();
}

class _MotorClaimsListScreenState extends State<MotorClaimsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilter = 0;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStatus;
    if (initial == ClaimStatus.approved || initial == ClaimStatus.rejected) {
      _selectedFilter = 2;
    } else if (initial != null) {
      _selectedFilter = 1;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilter(MotorClaim claim) {
    if (_selectedFilter == 1) {
      return claim.status == ClaimStatus.submitted ||
          claim.status == ClaimStatus.underReview ||
          claim.status == ClaimStatus.moreInfoRequired;
    }
    if (_selectedFilter == 2) {
      return claim.status == ClaimStatus.approved ||
          claim.status == ClaimStatus.rejected;
    }
    return true;
  }

  bool _matchesSearch(MotorClaim claim) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return claim.claimId.toLowerCase().contains(query) ||
        claim.vehicleRegistrationNumber.toLowerCase().contains(query) ||
        claim.vehicleMake.toLowerCase().contains(query) ||
        claim.vehicleModel.toLowerCase().contains(query) ||
        claim.policyId.toLowerCase().contains(query);
  }

  void _openSubmit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubmitMotorClaimScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claimService = MotorClaimService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Claims'),
        actions: [
          IconButton(
            tooltip: _showSearch ? 'Hide search' : 'Search claims',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) _searchController.clear();
              });
            },
            icon: Icon(_showSearch ? Icons.close : Icons.search_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListenableBuilder(
        listenable: claimService,
        builder: (context, _) {
          final filteredClaims = claimService.claims
              .where(_matchesFilter)
              .where(_matchesSearch)
              .toList();

          return RefreshIndicator(
            onRefresh: claimService.refreshClaims,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const Text(
                        'Your claims, in view.',
                        style: TextStyle(
                          color: InsureCareTheme.navy,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Follow every update, from start to resolution.',
                        style: TextStyle(
                          color: InsureCareTheme.muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _openSubmit,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Submit a new claim'),
                        ),
                      ),
                      if (_showSearch) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search vehicle, policy or claim number',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _FilterPill(
                            label: 'All claims',
                            selected: _selectedFilter == 0,
                            onTap: () => setState(() => _selectedFilter = 0),
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'In progress',
                            selected: _selectedFilter == 1,
                            onTap: () => setState(() => _selectedFilter = 1),
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'Closed',
                            selected: _selectedFilter == 2,
                            onTap: () => setState(() => _selectedFilter = 2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (claimService.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 52),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (claimService.lastError != null)
                        _EmptyClaimsState(
                          icon: Icons.cloud_off_outlined,
                          title: 'We could not load your claims.',
                          subtitle: 'Check your connection and Supabase setup, then try again.',
                          actionLabel: 'Try again',
                          onAction: claimService.refreshClaims,
                        )
                      else if (filteredClaims.isEmpty)
                        _EmptyClaimsState(
                          icon: Icons.description_outlined,
                          title: _selectedFilter == 0
                              ? 'No claims yet'
                              : _selectedFilter == 1
                              ? 'No claims in progress'
                              : 'No closed claims',
                          subtitle: 'Your submitted motor claims and their updates will appear here.',
                          actionLabel: 'Submit a new claim',
                          onAction: _openSubmit,
                        )
                      else
                        ...filteredClaims.map(
                          (claim) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _FigmaClaimCard(
                              claim: claim,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MotorClaimDetailsScreen(
                                    claimId: claim.claimId,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? InsureCareTheme.navy : Colors.white,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selected ? InsureCareTheme.navy : InsureCareTheme.border,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? Colors.white : InsureCareTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FigmaClaimCard extends StatelessWidget {
  const _FigmaClaimCard({required this.claim, required this.onTap});

  final MotorClaim claim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final milestones = claim.trackingMilestones.take(3).toList();
    final title = '${claim.vehicleMake} ${claim.vehicleModel}'.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: InsureCareTheme.border, width: 0.7),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title.isEmpty ? 'Motor claim' : title,
                      style: const TextStyle(
                        color: InsureCareTheme.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(status: claim.status),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${claim.claimId} · ${claim.vehicleRegistrationNumber}',
                style: const TextStyle(
                  color: InsureCareTheme.muted,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    claim.formattedAmount,
                    style: const TextStyle(
                      color: InsureCareTheme.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    claim.formattedIncidentDate,
                    style: const TextStyle(
                      color: InsureCareTheme.muted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ...milestones.asMap().entries.map(
                (entry) => _MilestoneLine(
                  milestone: entry.value,
                  isLast: entry.key == milestones.length - 1,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: InsureCareTheme.navy,
                    minimumSize: const Size(44, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: const Text(
                    'View details  ›',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ClaimStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontWeight: FontWeight.w700,
          fontSize: 9.5,
        ),
      ),
    );
  }
}

class _MilestoneLine extends StatelessWidget {
  const _MilestoneLine({required this.milestone, required this.isLast});

  final ClaimMilestone milestone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color tint = milestone.isCompleted
        ? const Color(0xFF3F8B75)
        : milestone.isCurrent
        ? InsureCareTheme.iconBlue
        : const Color(0xFF9AA8B6);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Icon(
                  milestone.isCompleted
                      ? Icons.check_circle_rounded
                      : milestone.isCurrent
                      ? Icons.schedule_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 17,
                  color: tint,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: InsureCareTheme.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: TextStyle(
                      color: tint,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    milestone.isCurrent
                        ? milestone.description
                        : milestone.date,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: InsureCareTheme.muted,
                      fontSize: 9.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyClaimsState extends StatelessWidget {
  const _EmptyClaimsState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: InsureCareTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: InsureCareTheme.iconBlue, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: InsureCareTheme.text,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: InsureCareTheme.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
