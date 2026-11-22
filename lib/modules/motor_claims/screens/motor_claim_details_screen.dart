import 'package:flutter/material.dart';
import '../../../common/models/claim_document.dart';
import '../../../common/models/claim_status.dart';
import '../models/motor_claim.dart';
import '../services/motor_claim_service.dart';
import '../widgets/accident_photo_upload_widget.dart';
import '../widgets/claim_status_badge.dart';
import '../widgets/claim_timeline_widget.dart';
import 'edit_motor_claim_screen.dart';

/// Screen displaying complete details, progress timeline, photos, and management actions for a Motor Claim.
class MotorClaimDetailsScreen extends StatelessWidget {
  final String claimId;

  const MotorClaimDetailsScreen({
    super.key,
    required this.claimId,
  });

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 13.0, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.indigo.shade50,
                  child: Icon(icon, size: 16, color: Colors.indigo),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  void _showStatusChangeDialog(BuildContext context, MotorClaim claim) {
    ClaimStatus selectedStatus = claim.status;
    final notesController = TextEditingController(text: claim.notes ?? '');
    final amountController = TextEditingController(
      text: claim.approvedAmount != null ? claim.approvedAmount.toString() : claim.claimAmount.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Update Status (Firebase Synced)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Allowed statuses ONLY: Submitted, UnderReview, MoreInfoRequired, Approved, Rejected.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ClaimStatus>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Claim Status'),
                  items: ClaimStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text('${s.label} (${s.value})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedStatus = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (selectedStatus == ClaimStatus.approved) ...[
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Approved Settlement Amount (\$)',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Assessor Notes / Remarks',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final claimService = MotorClaimService();
                final approvedAmt = double.tryParse(amountController.text.trim());
                claimService.updateClaimStatus(
                  claim.claimId,
                  selectedStatus,
                  notes: notesController.text.trim(),
                  approvedAmount: approvedAmt,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Status updated to ${selectedStatus.value} in state & Firebase!'),
                    backgroundColor: selectedStatus.color,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Status'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MotorClaim claim) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Claim?'),
        content: Text('Are you sure you want to withdraw claim ${claim.claimId}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, Keep Claim'),
          ),
          ElevatedButton(
            onPressed: () {
              MotorClaimService().deleteClaim(claim.claimId);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Claim withdrawn successfully.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Withdraw Claim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final claimService = MotorClaimService();

    return ListenableBuilder(
      listenable: claimService,
      builder: (context, _) {
        final claim = claimService.getClaimById(claimId);

        if (claim == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Claim Details')),
            body: const Center(
              child: Text('Claim not found or has been withdrawn.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(claim.claimId),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.rule_folder_outlined),
                tooltip: 'Update Status (Assessor)',
                onPressed: () => _showStatusChangeDialog(context, claim),
              ),
              if (claim.status == ClaimStatus.submitted ||
                  claim.status == ClaimStatus.underReview ||
                  claim.status == ClaimStatus.moreInfoRequired)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Claim',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditMotorClaimScreen(claim: claim),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header Status Banner
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                claim.vehicleDisplayName,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Policy: ${claim.policyId}  •  User: ${claim.userId}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          ClaimStatusBadge(status: claim.status),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Tracking Progress Stepper
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Claim Tracking Progress',
                              style: TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Status: ${claim.status.value}',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                color: claim.status.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClaimTimelineWidget(milestones: claim.trackingMilestones),
                      ],
                    ),
                  ),
                ),

                // Shared Core Fields Card
                _buildCard(
                  title: 'Shared Claim Information',
                  icon: Icons.shield_outlined,
                  children: [
                    _buildDetailRow('Claim ID (claimId)', claim.claimId, isBold: true),
                    _buildDetailRow('User ID (userId)', claim.userId),
                    _buildDetailRow('Policy ID (policyId)', claim.policyId),
                    _buildDetailRow('Claim Type (claimType)', claim.claimType),
                    _buildDetailRow('Claim Amount (claimAmount)', claim.formattedAmount, isBold: true),
                    _buildDetailRow('Status (status)', claim.status.value, valueColor: claim.status.color, isBold: true),
                    _buildDetailRow('Created At (createdAt)', claim.formattedSubmissionDate),
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Description (description):',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      claim.description,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),

                // Vehicle Specifications Card
                _buildCard(
                  title: 'Vehicle Details',
                  icon: Icons.directions_car_rounded,
                  children: [
                    _buildDetailRow('Registration Number', claim.vehicleRegistrationNumber, isBold: true),
                    _buildDetailRow('Make & Model', '${claim.vehicleMake} ${claim.vehicleModel}'),
                    _buildDetailRow('Manufacturing Year', claim.vehicleYear.toString()),
                    _buildDetailRow('Vehicle Type', claim.vehicleType),
                    _buildDetailRow(
                      'Drivable Status',
                      claim.isVehicleDrivable ? 'Yes (Safe to Drive)' : 'No (Requires Towing)',
                      valueColor: claim.isVehicleDrivable ? Colors.green : Colors.red,
                    ),
                  ],
                ),

                // Accident & Incident Details Card
                _buildCard(
                  title: 'Accident Details',
                  icon: Icons.warning_amber_rounded,
                  children: [
                    _buildDetailRow('Incident Date', claim.formattedIncidentDate),
                    _buildDetailRow('Incident Time', claim.incidentTime),
                    _buildDetailRow('Incident Location', claim.incidentLocation),
                    _buildDetailRow('Incident Type', claim.incidentType),
                    _buildDetailRow('Damage Severity', claim.damageSeverity, isBold: true),
                    _buildDetailRow(
                      'Police Report',
                      claim.policeReportFiled
                          ? 'Filed (${claim.policeReportNumber ?? 'Pending Reference'})'
                          : 'Not Filed',
                    ),
                  ],
                ),

                // Driver & Third-Party Card
                _buildCard(
                  title: 'Driver & Third-Party Details',
                  icon: Icons.people_outline_rounded,
                  children: [
                    _buildDetailRow('Driver Name', claim.driverName),
                    _buildDetailRow('Driving License', claim.driverLicenseNumber),
                    _buildDetailRow('Relationship to Insured', claim.relationshipToInsured),
                    _buildDetailRow('Third-Party Involved', claim.thirdPartyInvolved ? 'Yes' : 'No'),
                    if (claim.thirdPartyInvolved) ...[
                      const Divider(height: 16),
                      _buildDetailRow('Third-Party Name', claim.thirdPartyName ?? 'N/A'),
                      _buildDetailRow('Third-Party Vehicle', claim.thirdPartyVehicleNumber ?? 'N/A'),
                      _buildDetailRow('Third-Party Contact', claim.thirdPartyContact ?? 'N/A'),
                      _buildDetailRow('Third-Party Insurer', claim.thirdPartyInsurance ?? 'N/A'),
                    ],
                  ],
                ),

                // Accident Photos Gallery Card
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AccidentPhotoUploadWidget(
                      photos: claim.accidentPhotos,
                      isReadOnly: false,
                      onAddPhoto: (photoName) {
                        final newPhotoDoc = ClaimDocument(
                          documentId: 'PHOTO-${DateTime.now().millisecondsSinceEpoch}',
                          documentType: 'AccidentPhoto',
                          fileName: photoName,
                          fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/$photoName',
                          uploadedAt: DateTime.now(),
                        );
                        final updated = claim.copyWith(
                          documents: [...claim.documents, newPhotoDoc],
                        );
                        claimService.updateClaim(updated);
                      },
                      onRemovePhoto: (photoDoc) {
                        final updated = claim.copyWith(
                          documents: claim.documents.where((d) => d.documentId != photoDoc.documentId).toList(),
                        );
                        claimService.updateClaim(updated);
                      },
                    ),
                  ),
                ),

                // Supporting Documents Checklist Card
                _buildCard(
                  title: 'Supporting Documents (${claim.supportingDocuments.length})',
                  icon: Icons.attach_file_rounded,
                  children: [
                    if (claim.supportingDocuments.isEmpty)
                      const Text('No supporting documents attached.')
                    else
                      ...claim.supportingDocuments.map(
                        (doc) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.description_outlined, size: 20, color: Colors.indigo),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.fileName,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'ID: ${doc.documentId}  •  Type: ${doc.documentType}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle, size: 16, color: Colors.green),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Financial Summary Card
                _buildCard(
                  title: 'Financial & Assessor Notes',
                  icon: Icons.monetization_on_outlined,
                  children: [
                    _buildDetailRow('Claim Amount', claim.formattedAmount, isBold: true),
                    if (claim.approvedAmount != null)
                      _buildDetailRow(
                        'Approved Settlement Amount',
                        '\$${claim.approvedAmount!.toStringAsFixed(2)}',
                        isBold: true,
                        valueColor: Colors.green.shade700,
                      ),
                    if (claim.notes != null && claim.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Assessor Notes / Remarks:',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        claim.notes!,
                        style: TextStyle(fontSize: 13, color: Colors.indigo.shade900),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Bottom Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      if (claim.status == ClaimStatus.submitted ||
                          claim.status == ClaimStatus.underReview ||
                          claim.status == ClaimStatus.moreInfoRequired) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDelete(context, claim),
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            label: const Text('Withdraw Claim', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditMotorClaimScreen(claim: claim),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showStatusChangeDialog(context, claim),
                            icon: const Icon(Icons.sync_alt_rounded),
                            label: const Text('Change Status (Firebase)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
