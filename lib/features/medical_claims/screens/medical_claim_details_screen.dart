import 'dart:typed_data';

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
    return Theme(
      data: buildMedicalClaimsFigmaTheme(context),
      child: Scaffold(
        backgroundColor: MedicalClaimsColors.canvas,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          titleSpacing: 0,
          title: const Text('Medical Claim Details'),
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: service,
            builder: (context, _) {
              final claim = service.findClaim(claimId);
              if (claim == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Medical claim not found.',
                      style: TextStyle(
                        color: MedicalClaimsColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      // Dark Navy Hero Card (matching Figma 2-27 style)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: MedicalClaimsColors.navy,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.favorite_border_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        claim.hospitalName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${claim.treatmentType} · Policy ${claim.policyId}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.75,
                                          ),
                                          fontSize: 12.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  claim.claimId,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                MedicalStatusBadge(status: claim.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              formatLkr(claim.claimAmount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Submitted ${formatFigmaDate(claim.createdAt)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (claim.status ==
                          MedicalClaimStatus.moreInfoRequired) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: MedicalClaimsColors.infoReqBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: MedicalClaimsColors.infoReqFg,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Operations requested additional supporting medical bills or discharge reports.',
                                  style: TextStyle(
                                    color: MedicalClaimsColors.infoReqFg,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      MedicalClaimStatusTimeline(
                        status: claim.status,
                        submittedAt: claim.createdAt,
                      ),
                      const SizedBox(height: 14),
                      _FigmaInfoCard(
                        title: 'Patient & Hospital Information',
                        rows: [
                          _KeyValueRow('Patient name', claim.patientName),
                          _KeyValueRow('Relationship', claim.patientRelationship),
                          _KeyValueRow('Hospital', claim.hospitalName),
                          _KeyValueRow('Treatment type', claim.treatmentType),
                          if (claim.admissionDate != null)
                            _KeyValueRow(
                              'Admission / Visit date',
                              formatFigmaDate(claim.admissionDate!),
                            ),
                          if (claim.dischargeDate != null)
                            _KeyValueRow(
                              'Discharge date',
                              formatFigmaDate(claim.dischargeDate!),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _FigmaInfoCard(
                        title: 'Billing & Claim Summary',
                        rows: [
                          _KeyValueRow('Policy ID', claim.policyId),
                          if (claim.billNumber != null &&
                              claim.billNumber!.isNotEmpty)
                            _KeyValueRow('Bill number', claim.billNumber!),
                          if (claim.billDate != null)
                            _KeyValueRow(
                              'Bill date',
                              formatFigmaDate(claim.billDate!),
                            ),
                          _KeyValueRow('What happened', claim.description),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: MedicalClaimsColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Supporting documents (${claim.documents.length})',
                              style: const TextStyle(
                                color: MedicalClaimsColors.navy,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (claim.documents.isEmpty)
                              const Text(
                                'No supporting documents attached.',
                                style: TextStyle(
                                  color: MedicalClaimsColors.textSecondary,
                                  fontSize: 13,
                                ),
                              )
                            else
                              for (final doc in claim.documents)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _StoredDocumentTile(
                                    document: doc,
                                    onView: () => _openDocumentPreview(
                                      context,
                                      doc,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openDocumentPreview(
    BuildContext context,
    MedicalBillDocument document,
  ) async {
    final bytes = await service.downloadClaimDocument(document);
    if (!context.mounted) return;

    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Document "${document.fileName}" stored in Supabase bucket claim-documents (${document.storagePath}).',
          ),
        ),
      );
      return;
    }

    _showBytesDialog(context, document, bytes);
  }

  void _showBytesDialog(
    BuildContext context,
    MedicalBillDocument document,
    Uint8List bytes,
  ) {
    final isPdf = document.fileName.toLowerCase().endsWith('.pdf');

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.white,
                title: Text(
                  document.fileName,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              Flexible(
                child: isPdf
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Downloaded PDF (${(bytes.length / 1024).toStringAsFixed(1)} KB) from private bucket claim-documents.',
                        ),
                      )
                    : InteractiveViewer(
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Unable to render image preview.'),
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

class _FigmaInfoCard extends StatelessWidget {
  const _FigmaInfoCard({required this.title, required this.rows});

  final String title;
  final List<_KeyValueRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MedicalClaimsColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: MedicalClaimsColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 18, color: MedicalClaimsColors.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: MedicalClaimsColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: MedicalClaimsColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StoredDocumentTile extends StatelessWidget {
  const _StoredDocumentTile({
    required this.document,
    required this.onView,
  });

  final MedicalBillDocument document;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MedicalClaimsColors.softBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MedicalClaimsColors.softBlueBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: MedicalClaimsColors.navy,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.fileName,
                  style: const TextStyle(
                    color: MedicalClaimsColors.navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${document.documentType} · ${formatFigmaDate(document.uploadedAt)}',
                  style: const TextStyle(
                    color: MedicalClaimsColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'View / Download from Supabase',
            icon: const Icon(
              Icons.download_for_offline_outlined,
              color: MedicalClaimsColors.accentBlue,
            ),
            onPressed: onView,
          ),
        ],
      ),
    );
  }
}
