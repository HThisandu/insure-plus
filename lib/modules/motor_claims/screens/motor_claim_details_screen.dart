import 'package:flutter/material.dart';

import '../../../common/models/claim_document.dart';
import '../../../common/models/claim_status.dart';
import '../../../common/theme/insurecare_theme.dart';
import '../models/motor_claim.dart';
import '../services/motor_claim_service.dart';
import '../services/motor_claim_storage_service.dart';

import 'package:url_launcher/url_launcher.dart';

import '../widgets/accident_photo_upload_widget.dart';
import '../widgets/claim_status_badge.dart';
import '../widgets/claim_timeline_widget.dart';
import 'edit_motor_claim_screen.dart';

/// Screen displaying complete details, progress timeline, photos, and management actions for a Motor Claim.
class MotorClaimDetailsScreen extends StatelessWidget {
  final String claimId;

  Future<void> _openPrivateDocument(
    BuildContext context,
    ClaimDocument document,
  ) async {
    try {
      final signedUrl = await MotorClaimStorageService.instance
          .createDownloadUrl(document.fileUrl);
      final opened = await launchUrl(
        Uri.parse(signedUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the document.')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create a private download link: $error'),
        ),
      );
    }
  }

  const MotorClaimDetailsScreen({super.key, required this.claimId});

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: InsureCareTheme.border, width: 0.7),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: InsureCareTheme.paleBlue,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: InsureCareTheme.iconBlue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: InsureCareTheme.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
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
        content: Text(
          'Are you sure you want to withdraw claim ${claim.claimId}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, Keep Claim'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await MotorClaimService().deleteClaim(claim.claimId);
                if (!context.mounted) return;
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Claim withdrawn successfully from Supabase.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not withdraw claim: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
            body: Center(
              child: claimService.isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      claimService.lastError == null
                          ? 'Claim not found or has been withdrawn.'
                          : 'Could not load this claim from Supabase: ${claimService.lastError}',
                      textAlign: TextAlign.center,
                    ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(claim.claimId),
            actions: [
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
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: InsureCareTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.vehicleDisplayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: InsureCareTheme.navy,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Policy: ${claim.policyId}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: InsureCareTheme.muted,
                              ),
                            ),
                          ),
                          ClaimStatusBadge(status: claim.status),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(
                        claim.formattedAmount,
                        style: const TextStyle(
                          color: InsureCareTheme.navy,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Claim amount',
                        style: TextStyle(
                          color: InsureCareTheme.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Tracking Progress Stepper
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(
                      color: InsureCareTheme.border,
                      width: 0.7,
                    ),
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
                              'Claim tracking progress',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: InsureCareTheme.text,
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
                        ClaimTimelineWidget(
                          milestones: claim.trackingMilestones,
                        ),
                      ],
                    ),
                  ),
                ),

                // Shared Core Fields Card
                _buildCard(
                  title: 'Shared Claim Information',
                  icon: Icons.shield_outlined,
                  children: [
                    _buildDetailRow(
                      'Claim ID (claimId)',
                      claim.claimId,
                      isBold: true,
                    ),
                    _buildDetailRow('Policy ID (policyId)', claim.policyId),
                    _buildDetailRow('Claim Type (claimType)', claim.claimType),
                    _buildDetailRow(
                      'Claim Amount (claimAmount)',
                      claim.formattedAmount,
                      isBold: true,
                    ),
                    _buildDetailRow(
                      'Status (status)',
                      claim.status.value,
                      valueColor: claim.status.color,
                      isBold: true,
                    ),
                    _buildDetailRow(
                      'Created At (createdAt)',
                      claim.formattedSubmissionDate,
                    ),
                    const SizedBox(height: 6),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Description (description):',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
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
                    _buildDetailRow(
                      'Registration Number',
                      claim.vehicleRegistrationNumber,
                      isBold: true,
                    ),
                    _buildDetailRow(
                      'Make & Model',
                      '${claim.vehicleMake} ${claim.vehicleModel}',
                    ),
                    _buildDetailRow(
                      'Manufacturing Year',
                      claim.vehicleYear.toString(),
                    ),
                    _buildDetailRow('Vehicle Type', claim.vehicleType),
                    _buildDetailRow(
                      'Drivable Status',
                      claim.isVehicleDrivable
                          ? 'Yes (Safe to Drive)'
                          : 'No (Requires Towing)',
                      valueColor: claim.isVehicleDrivable
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),

                // Accident & Incident Details Card
                _buildCard(
                  title: 'Accident Details',
                  icon: Icons.warning_amber_rounded,
                  children: [
                    _buildDetailRow(
                      'Incident Date',
                      claim.formattedIncidentDate,
                    ),
                    _buildDetailRow('Incident Time', claim.incidentTime),
                    _buildDetailRow(
                      'Incident Location',
                      claim.incidentLocation,
                    ),
                    _buildDetailRow('Incident Type', claim.incidentType),
                    _buildDetailRow(
                      'Damage Severity',
                      claim.damageSeverity,
                      isBold: true,
                    ),
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
                    _buildDetailRow(
                      'Driving License',
                      claim.driverLicenseNumber,
                    ),
                    _buildDetailRow(
                      'Relationship to Insured',
                      claim.relationshipToInsured,
                    ),
                    _buildDetailRow(
                      'Third-Party Involved',
                      claim.thirdPartyInvolved ? 'Yes' : 'No',
                    ),
                    if (claim.thirdPartyInvolved) ...[
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Third-Party Name',
                        claim.thirdPartyName ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Third-Party Vehicle',
                        claim.thirdPartyVehicleNumber ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Third-Party Contact',
                        claim.thirdPartyContact ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Third-Party Insurer',
                        claim.thirdPartyInsurance ?? 'N/A',
                      ),
                    ],
                  ],
                ),

                // Accident Photos Gallery Card
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AccidentPhotoUploadWidget(
                      photos: claim.accidentPhotos,
                      isReadOnly: true,
                      resolvePhotoUrl: (photo) => MotorClaimStorageService
                          .instance
                          .createDownloadUrl(photo.fileUrl),
                      onAddPhoto: (photoName) {
                        final newPhotoDoc = ClaimDocument(
                          documentId:
                              'PHOTO-${DateTime.now().millisecondsSinceEpoch}',
                          documentType: 'AccidentPhoto',
                          fileName: photoName,
                          fileUrl:
                              'gs://insure-plus.appspot.com/motor_claims/photos/$photoName',
                          uploadedAt: DateTime.now(),
                        );
                        final updated = claim.copyWith(
                          documents: [...claim.documents, newPhotoDoc],
                        );
                        claimService.updateClaim(updated);
                      },
                      onRemovePhoto: (photoDoc) {
                        final updated = claim.copyWith(
                          documents: claim.documents
                              .where((d) => d.documentId != photoDoc.documentId)
                              .toList(),
                        );
                        claimService.updateClaim(updated);
                      },
                    ),
                  ),
                ),

                // Supporting Documents Checklist Card
                _buildCard(
                  title:
                      'Supporting Documents (${claim.supportingDocuments.length})',
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
                              const Icon(
                                Icons.description_outlined,
                                size: 20,
                                color: InsureCareTheme.navy,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.fileName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'ID: ${doc.documentId}  •  Type: ${doc.documentType}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Open private document',
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 18,
                                  color: InsureCareTheme.navy,
                                ),
                                onPressed: doc.fileUrl.startsWith('gs://')
                                    ? null
                                    : () => _openPrivateDocument(context, doc),
                              ),
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
                    _buildDetailRow(
                      'Claim Amount',
                      claim.formattedAmount,
                      isBold: true,
                    ),
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
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        claim.notes!,
                        style: TextStyle(
                          fontSize: 13,
                          color: InsureCareTheme.navy,
                        ),
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
                      if (claim.status == ClaimStatus.submitted) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDelete(context, claim),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Withdraw Claim',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                                  builder: (_) =>
                                      EditMotorClaimScreen(claim: claim),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: InsureCareTheme.navy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: InsureCareTheme.paleBlue,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Your claim decision and status updates will be shared here by the claims team.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: InsureCareTheme.navy,
                                fontSize: 12,
                                height: 1.4,
                              ),
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
