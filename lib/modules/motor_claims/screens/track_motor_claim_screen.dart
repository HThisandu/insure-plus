import 'package:flutter/material.dart';

import '../../../common/theme/insurecare_theme.dart';
import '../models/motor_claim.dart';
import '../services/motor_claim_service.dart';
import '../widgets/claim_status_badge.dart';
import '../widgets/claim_timeline_widget.dart';
import 'motor_claim_details_screen.dart';

/// Screen allowing quick search and live tracking of a motor claim's progress milestones.
class TrackMotorClaimScreen extends StatefulWidget {
  final String? initialQuery;

  const TrackMotorClaimScreen({super.key, this.initialQuery});

  @override
  State<TrackMotorClaimScreen> createState() => _TrackMotorClaimScreenState();
}

class _TrackMotorClaimScreenState extends State<TrackMotorClaimScreen> {
  final TextEditingController _queryController = TextEditingController();
  MotorClaim? _searchedClaim;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _queryController.text = widget.initialQuery!;
      _performSearch();
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    final claimService = MotorClaimService();
    final results = claimService.getFilteredClaims(searchQuery: query);

    setState(() {
      _hasSearched = true;
      _searchedClaim = results.isNotEmpty ? results.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track claim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Box
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Claim ID or Vehicle Number',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _queryController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText:
                                  'Your claim reference or vehicle number',
                              filled: true,
                              fillColor: InsureCareTheme.background,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _performSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: InsureCareTheme.navy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Track'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Search Result
            if (_hasSearched && _searchedClaim == null) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 54,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No claim matches that reference.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Please verify your claim reference ID or vehicle registration number and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_searchedClaim != null) ...[
              // Summary Banner
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _searchedClaim!.claimId,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: InsureCareTheme.navy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ClaimStatusBadge(status: _searchedClaim!.status),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        _searchedClaim!.vehicleDisplayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Policy: ${_searchedClaim!.policyId}  •  Status: ${_searchedClaim!.status.value}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Claim Amount: ${_searchedClaim!.formattedAmount}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tracking Stepper
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Milestone Status',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClaimTimelineWidget(
                        milestones: _searchedClaim!.trackingMilestones,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // View Full Details Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MotorClaimDetailsScreen(
                          claimId: _searchedClaim!.claimId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('View Full Claim Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: InsureCareTheme.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
