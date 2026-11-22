import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/medical_bill_document.dart';
import '../models/medical_claim_status.dart';
import '../services/medical_claim_service.dart';
import '../widgets/medical_claim_status_timeline.dart';
import '../widgets/medical_status_badge.dart';

class MedicalClaimDetailsScreen extends StatelessWidget {
  const MedicalClaimDetailsScreen({
    super.key,
    required this.service,
    required this.claimId,
  });

  final MedicalClaimService service;
  final String claimId;

  @override
  Widget build(BuildContext context) {
    final dates = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Medical Claim Details')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: service,
          builder: (context, _) {
            final claim = service.findClaim(claimId);
            if (claim == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_outlined,
                        size: 48,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Medical claim not found.',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      color: colors.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    claim.claimId,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: colors.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                MedicalStatusBadge(status: claim.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              formatLkr(claim.claimAmount),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Policy ${claim.policyId} · Submitted ${dates.formatMediumDate(claim.createdAt.toLocal())}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (claim.status == MedicalClaimStatus.moreInfoRequired) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: colors.tertiaryContainer,
                        child: ListTile(
                          leading: Icon(
                            Icons.info_outline,
                            color: colors.onTertiaryContainer,
                          ),
                          title: Text(
                            'Additional documents requested',
                            style: TextStyle(
                              color: colors.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Please contact hospital coordination or submit updated bills requested by claims operations.',
                            style: TextStyle(color: colors.onTertiaryContainer),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    MedicalClaimStatusTimeline(status: claim.status),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient & Hospital Information',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(
                              icon: Icons.person_outline,
                              label: 'Patient name',
                              value: claim.patientName,
                            ),
                            _DetailRow(
                              icon: Icons.family_restroom_outlined,
                              label: 'Relationship',
                              value: claim.patientRelationship,
                            ),
                            _DetailRow(
                              icon: Icons.local_hospital_outlined,
                              label: 'Hospital',
                              value: claim.hospitalName,
                            ),
                            _DetailRow(
                              icon: Icons.medical_services_outlined,
                              label: 'Treatment type',
                              value: claim.treatmentType,
                            ),
                            if (claim.admissionDate != null)
                              _DetailRow(
                                icon: Icons.login_outlined,
                                label: 'Admission date',
                                value: dates.formatMediumDate(
                                  claim.admissionDate!.toLocal(),
                                ),
                              ),
                            if (claim.dischargeDate != null)
                              _DetailRow(
                                icon: Icons.logout_outlined,
                                label: 'Discharge date',
                                value: dates.formatMediumDate(
                                  claim.dischargeDate!.toLocal(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Billing & Treatment Summary',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (claim.billNumber != null &&
                                claim.billNumber!.isNotEmpty)
                              _DetailRow(
                                icon: Icons.receipt_outlined,
                                label: 'Bill number',
                                value: claim.billNumber!,
                              ),
                            if (claim.billDate != null)
                              _DetailRow(
                                icon: Icons.event_outlined,
                                label: 'Bill date',
                                value: dates.formatMediumDate(
                                  claim.billDate!.toLocal(),
                                ),
                              ),
                            _DetailRow(
                              icon: Icons.notes_outlined,
                              label: 'Description',
                              value: claim.description,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attached Medical Bills (${claim.documents.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (claim.documents.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No medical bill documents attached.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              )
                            else
                              for (final document in claim.documents)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        colors.surfaceContainerHighest,
                                    child: const Icon(
                                      Icons.description_outlined,
                                    ),
                                  ),
                                  title: Text(
                                    document.fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${document.documentType} · ${dates.formatMediumDate(document.uploadedAt.toLocal())}',
                                  ),
                                  trailing: _canPreviewDocument(document)
                                      ? IconButton(
                                          tooltip: 'Preview bill',
                                          icon: const Icon(
                                            Icons.visibility_outlined,
                                          ),
                                          onPressed: () =>
                                              _showDocumentPreview(
                                                context,
                                                document,
                                              ),
                                        )
                                      : null,
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _canPreviewDocument(MedicalBillDocument document) {
    final url = document.downloadUrl?.trim();
    if (url == null || url.isEmpty) return false;
    if (url.startsWith('http://') || url.startsWith('https://')) return true;
    return !kIsWeb && File(url).existsSync();
  }

  void _showDocumentPreview(
    BuildContext context,
    MedicalBillDocument document,
  ) {
    final url = document.downloadUrl?.trim();
    if (url == null || url.isEmpty) return;
    final isNetwork = url.startsWith('http://') || url.startsWith('https://');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                title: Text(
                  document.fileName,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              Flexible(
                child: InteractiveViewer(
                  child: isNetwork
                      ? Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Unable to load bill preview.'),
                          ),
                        )
                      : Image.file(
                          File(url),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Unable to load local bill preview.'),
                          ),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
