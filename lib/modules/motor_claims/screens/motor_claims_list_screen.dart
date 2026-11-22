import 'package:flutter/material.dart';
import '../../../common/models/claim_status.dart';
import '../services/motor_claim_service.dart';
import '../widgets/motor_claim_card.dart';
import 'submit_motor_claim_screen.dart';
import 'motor_claim_details_screen.dart';

/// Screen listing all submitted motor claims with search and filter chips
/// for the 5 allowed statuses: Submitted, UnderReview, MoreInfoRequired, Approved, Rejected.
class MotorClaimsListScreen extends StatefulWidget {
  final ClaimStatus? initialStatus;

  const MotorClaimsListScreen({
    super.key,
    this.initialStatus,
  });

  @override
  State<MotorClaimsListScreen> createState() => _MotorClaimsListScreenState();
}

class _MotorClaimsListScreenState extends State<MotorClaimsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  ClaimStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claimService = MotorClaimService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Motor Claims'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: claimService,
        builder: (context, _) {
          final claims = claimService.getFilteredClaims(
            status: _selectedStatus,
            searchQuery: _searchController.text,
          );

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by Claim ID, Vehicle No, or Policy ID...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.indigo),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Filter Chips for the 5 allowed statuses
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedStatus == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = null;
                        });
                      },
                      selectedColor: Colors.indigo.shade100,
                      checkmarkColor: Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    ...ClaimStatus.values.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(status.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = selected ? status : null;
                            });
                          },
                          selectedColor: status.backgroundColor,
                          checkmarkColor: status.color,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Claims List or Empty State
              Expanded(
                child: claims.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No Motor Claims Found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchController.text.isNotEmpty || _selectedStatus != null
                                    ? 'Try adjusting your search query or status filter.'
                                    : 'You have not submitted any motor claims yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SubmitMotorClaimScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('File New Claim'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: claims.length,
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemBuilder: (context, index) {
                          final claim = claims[index];
                          return MotorClaimCard(
                            claim: claim,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MotorClaimDetailsScreen(claimId: claim.claimId),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SubmitMotorClaimScreen(),
            ),
          );
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('File Claim'),
      ),
    );
  }
}
