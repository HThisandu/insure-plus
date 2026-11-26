import 'package:flutter/material.dart';

import 'models/ocr_bill_data.dart';
import 'screens/medical_claims_home_screen.dart';
import 'services/medical_claim_repository.dart';
import 'services/medical_claim_service.dart';
import 'widgets/medical_status_badge.dart';

void main() => runApp(const MedicalClaimsPreview());

class MedicalClaimsPreview extends StatefulWidget {
  const MedicalClaimsPreview({super.key});

  @override
  State<MedicalClaimsPreview> createState() => _MedicalClaimsPreviewState();
}

class _MedicalClaimsPreviewState extends State<MedicalClaimsPreview> {
  late final InMemoryMedicalClaimRepository _repository =
      InMemoryMedicalClaimRepository();
  late final MedicalClaimService _service = MedicalClaimService(
    repository: _repository,
    userId: 'DEMO-USER-01',
  );

  @override
  void dispose() {
    _service.dispose();
    _repository.dispose();
    super.dispose();
  }

  Future<OcrBillData?> _sampleOcrScan(BuildContext context) async {
    return showDialog<OcrBillData>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sample Bill OCR'),
        content: const Text(
          'Fill the form using sample scanned medical bill details?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              OcrBillData(
                hospitalName: 'Durdans Hospital',
                billNumber: 'DRD-2026-55018',
                billDate: DateTime(2026, 11, 21),
                amount: 16800.00,
              ),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insure-Plus Medical Claims',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MedicalClaimsColors.navy,
          primary: MedicalClaimsColors.navy,
        ),
      ),
      home: MedicalClaimsHomeScreen(
        service: _service,
        onScanBillWithOcr: _sampleOcrScan,
      ),
    );
  }
}
