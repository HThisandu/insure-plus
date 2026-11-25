import 'package:flutter/material.dart';

import 'models/claim.dart';
import 'models/claim_document.dart';
import 'screens/claims_dashboard_screen.dart';
import 'services/claim_service.dart';

void main() => runApp(const ClaimManagementPreview());

class ClaimManagementPreview extends StatefulWidget {
  const ClaimManagementPreview({super.key});

  @override
  State<ClaimManagementPreview> createState() => _ClaimManagementPreviewState();
}

class _ClaimManagementPreviewState extends State<ClaimManagementPreview> {
  late final ClaimService _service = ClaimService([
    Claim(
      claimId: 'CLAIM001',
      userId: 'DEMO-USER-01',
      policyId: 'MOTOR-001',
      claimType: 'Motor',
      claimAmount: 45000,
      description: 'Repair estimate for front bumper damage.',
      status: ClaimStatus.submitted,
      documents: [
        ClaimDocument(
          documentId: 'DOC001',
          documentType: 'Repair estimate',
          fileName: 'repair-estimate.pdf',
          storagePath: 'CLAIM001/repair-estimate.pdf',
          uploadedAt: DateTime(2026, 11, 18),
        ),
      ],
      createdAt: DateTime(2026, 11, 18),
    ),
    Claim(
      claimId: 'CLAIM002',
      userId: 'DEMO-USER-02',
      policyId: 'MEDICAL-001',
      claimType: 'Medical',
      claimAmount: 18500,
      description: 'Reimbursement request for an outpatient procedure.',
      status: ClaimStatus.underReview,
      documents: const [],
      createdAt: DateTime(2026, 11, 16),
    ),
  ]);

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Claim Management Preview',
      home: ClaimsDashboardScreen(service: _service),
    );
  }
}
