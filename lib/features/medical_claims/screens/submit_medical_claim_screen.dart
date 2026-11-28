import 'package:flutter/material.dart';

import '../models/medical_bill_document.dart';
import '../models/medical_claim.dart';
import '../models/ocr_bill_data.dart';
import '../services/medical_claim_service.dart';
import '../widgets/medical_bill_upload_card.dart';
import '../widgets/medical_status_badge.dart';

typedef OcrBillScannerCallback = Future<OcrBillData?> Function(
  BuildContext context,
);

class MedicalPolicyOption {
  const MedicalPolicyOption({
    required this.policyId,
    required this.planName,
    required this.remainingBalanceLkr,
  });

  final String policyId;
  final String planName;
  final double remainingBalanceLkr;

  String get displayLabel =>
      '$planName · $policyId (Balance ${formatLkr(remainingBalanceLkr)})';
}

class SubmitMedicalClaimScreen extends StatefulWidget {
  const SubmitMedicalClaimScreen({
    super.key,
    required this.service,
    required this.userId,
    this.initialPolicyId,
    this.ocrPrefill,
    this.onScanBillWithOcr,
  });

  final MedicalClaimService service;
  final String userId;
  final String? initialPolicyId;
  final OcrBillData? ocrPrefill;
  final OcrBillScannerCallback? onScanBillWithOcr;

  static const List<MedicalPolicyOption> defaultPolicies = [
    MedicalPolicyOption(
      policyId: 'MEDICAL-001',
      planName: 'Health Plus',
      remainingBalanceLkr: 250000.00,
    ),
    MedicalPolicyOption(
      policyId: 'MEDICAL-002',
      planName: 'Executive Surgical Cover',
      remainingBalanceLkr: 500000.00,
    ),
    MedicalPolicyOption(
      policyId: 'MEDICAL-003',
      planName: 'Outpatient & Lab Care',
      remainingBalanceLkr: 75000.00,
    ),
  ];

  @override
  State<SubmitMedicalClaimScreen> createState() =>
      _SubmitMedicalClaimScreenState();
}

class _SubmitMedicalClaimScreenState extends State<SubmitMedicalClaimScreen> {
  static const List<String> _hospitals = [
    'Asiri Hospital',
    'Nawaloka Hospital',
    'Lanka Hospitals',
    'Durdans Hospital',
    'Hemas Hospital',
  ];

  final _formKey = GlobalKey<FormState>();

  late final List<MedicalPolicyOption> _policies;
  late String _selectedPolicyId;

  final _patientController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _billNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _relationship = MedicalClaim.relationships.first;
  String _treatmentType = MedicalClaim.treatmentTypes.first;
  DateTime _admissionDate = DateTime.now();
  DateTime? _dischargeDate;
  DateTime? _billDate;
  final List<PendingMedicalAttachment> _attachments = [];
  bool _ocrApplied = false;

  MedicalPolicyOption get _currentPolicy => _policies.firstWhere(
    (p) => p.policyId == _selectedPolicyId,
    orElse: () => _policies.first,
  );

  bool get _isOverBalance {
    final val = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );
    return val != null && val > _currentPolicy.remainingBalanceLkr;
  }

  @override
  void initState() {
    super.initState();
    _policies = List<MedicalPolicyOption>.from(
      SubmitMedicalClaimScreen.defaultPolicies,
    );

    final initialId = widget.initialPolicyId?.trim();
    if (initialId != null && initialId.isNotEmpty) {
      if (!_policies.any((p) => p.policyId == initialId)) {
        _policies.insert(
          0,
          MedicalPolicyOption(
            policyId: initialId,
            planName: 'Health Plus',
            remainingBalanceLkr: 250000.00,
          ),
        );
      }
      _selectedPolicyId = initialId;
    } else {
      _selectedPolicyId = _policies.first.policyId;
    }

    if (widget.ocrPrefill != null) {
      _fillFromOcr(widget.ocrPrefill!, showNotice: false);
    }
  }

  @override
  void dispose() {
    _patientController.dispose();
    _hospitalController.dispose();
    _billNumberController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _fillFromOcr(OcrBillData data, {bool showNotice = true}) {
    if (data.hospitalName != null && data.hospitalName!.trim().isNotEmpty) {
      _hospitalController.text = data.hospitalName!.trim();
    }
    if (data.billNumber != null && data.billNumber!.trim().isNotEmpty) {
      _billNumberController.text = data.billNumber!.trim();
    }
    if (data.amount != null && data.amount! > 0) {
      _amountController.text = data.amount!.toStringAsFixed(2);
    }
    if (data.billDate != null) {
      _billDate = data.billDate;
    }
    if (data.hasImage) {
      final path = data.localImagePath!.trim();
      final name = path.split('/').last.split('\\').last;
      if (!_attachments.any((a) => a.localPath == path)) {
        _attachments.add(
          PendingMedicalAttachment(
            fileName: name.isEmpty ? 'bill.jpg' : name,
            localPath: path,
          ),
        );
      }
    }
    _ocrApplied = data.hasExtractedFields || data.hasImage;

    if (showNotice && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Auto-filled from AI Bill OCR — please verify details.',
          ),
        ),
      );
    }
  }

  Future<void> _scanWithOcr() async {
    if (widget.onScanBillWithOcr == null) return;
    final data = await widget.onScanBillWithOcr!(context);
    if (data != null && mounted) {
      _fillFromOcr(data);
    }
  }

  Future<void> _selectDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
    DateTime? firstDate,
  }) async {
    final now = DateTime.now();
    final minDate = firstDate ?? DateTime(now.year - 2);
    var initial = current ?? now;
    if (initial.isBefore(minDate)) initial = minDate;
    if (initial.isAfter(now)) initial = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate,
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_dischargeDate != null && _dischargeDate!.isBefore(_admissionDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discharge date cannot be before admission date.'),
        ),
      );
      return;
    }

    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );
    if (amount == null || amount <= 0) return;

    final created = await widget.service.submitMedicalClaim(
      userId: widget.userId,
      policyId: _selectedPolicyId,
      claimAmount: amount,
      description: _descriptionController.text,
      patientName: _patientController.text,
      patientRelationship: _relationship,
      hospitalName: _hospitalController.text,
      treatmentType: _treatmentType,
      admissionDate: _admissionDate,
      dischargeDate: _dischargeDate,
      billNumber: _billNumberController.text,
      billDate: _billDate,
      attachments: List<PendingMedicalAttachment>.from(_attachments),
    );

    if (!mounted) return;
    if (created != null) {
      Navigator.of(context).pop(created);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.service.errorMessage ?? 'Could not submit medical claim.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = MaterialLocalizations.of(context);

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
          title: const Text('Let\'s get you covered.'),
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: widget.service,
            builder: (context, _) {
              final busy = widget.service.isSubmitting;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Submit a claim in a few simple steps.',
                            style: TextStyle(
                              color: MedicalClaimsColors.textSecondary,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: MedicalClaimsColors.softBlue,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: MedicalClaimsColors.softBlueBorder,
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.verified_user_outlined,
                                  color: MedicalClaimsColors.accentBlue,
                                  size: 22,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Here when you need us.',
                                        style: TextStyle(
                                          color: MedicalClaimsColors.navy,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Have your policy details and supporting documents ready. We\'ll take care of the rest.',
                                        style: TextStyle(
                                          color:
                                              MedicalClaimsColors.textSecondary,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_ocrApplied) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: MedicalClaimsColors.successBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Auto-filled from AI Bill OCR — please verify details',
                                style: TextStyle(
                                  color: MedicalClaimsColors.successFg,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const _InputLabel('Select policy'),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPolicyId,
                            isExpanded: true,
                            items: [
                              for (final p in _policies)
                                DropdownMenuItem(
                                  value: p.policyId,
                                  child: Text(
                                    p.displayLabel,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: busy
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() => _selectedPolicyId = val);
                                    }
                                  },
                          ),
                          const SizedBox(height: 14),
                          const _InputLabel('Patient Name'),
                          TextFormField(
                            controller: _patientController,
                            enabled: !busy,
                            decoration: const InputDecoration(
                              labelText: 'Patient Name',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              hintText: 'e.g. Kasun Perera',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Patient name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          const _InputLabel('Relationship'),
                          DropdownButtonFormField<String>(
                            initialValue: _relationship,
                            isExpanded: true,
                            items: [
                              for (final rel in MedicalClaim.relationships)
                                DropdownMenuItem(value: rel, child: Text(rel)),
                            ],
                            onChanged: busy
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() => _relationship = val);
                                    }
                                  },
                          ),
                          const SizedBox(height: 14),
                          const _InputLabel('Hospital Name'),
                          TextFormField(
                            controller: _hospitalController,
                            enabled: !busy,
                            decoration: const InputDecoration(
                              labelText: 'Hospital Name',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              hintText: 'e.g. Asiri Hospital',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Hospital name is required'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final h in _hospitals)
                                ActionChip(
                                  label: Text(
                                    h,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: MedicalClaimsColors.border,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: busy
                                      ? null
                                      : () => setState(
                                          () => _hospitalController.text = h,
                                        ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const _InputLabel('Treatment Type'),
                          DropdownButtonFormField<String>(
                            initialValue: _treatmentType,
                            isExpanded: true,
                            items: [
                              for (final type in MedicalClaim.treatmentTypes)
                                DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                            ],
                            onChanged: busy
                                ? null
                                : (val) {
                                    if (val != null) {
                                      setState(() => _treatmentType = val);
                                    }
                                  },
                          ),
                          const SizedBox(height: 14),
                          _DateBox(
                            label: 'Admission / Visit Date',
                            value: dates.formatMediumDate(_admissionDate),
                            enabled: !busy,
                            onTap: () => _selectDate(
                              current: _admissionDate,
                              onPicked: (d) {
                                _admissionDate = d;
                                if (_dischargeDate != null &&
                                    _dischargeDate!.isBefore(d)) {
                                  _dischargeDate = null;
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DateBox(
                            label: 'Discharge Date (Optional)',
                            value: _dischargeDate != null
                                ? dates.formatMediumDate(_dischargeDate!)
                                : null,
                            enabled: !busy,
                            onTap: () => _selectDate(
                              current: _dischargeDate ?? _admissionDate,
                              firstDate: _admissionDate,
                              onPicked: (d) => _dischargeDate = d,
                            ),
                            onClear: _dischargeDate != null
                                ? () => setState(() => _dischargeDate = null)
                                : null,
                          ),
                          const SizedBox(height: 14),
                          const _InputLabel('Bill Number (Optional)'),
                          TextFormField(
                            controller: _billNumberController,
                            enabled: !busy,
                            decoration: const InputDecoration(
                              labelText: 'Bill Number (Optional)',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              hintText: 'e.g. ASH-2026-88412',
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DateBox(
                            label: 'Bill Date (Optional)',
                            value: _billDate != null
                                ? dates.formatMediumDate(_billDate!)
                                : null,
                            enabled: !busy,
                            onTap: () => _selectDate(
                              current: _billDate,
                              onPicked: (d) => _billDate = d,
                            ),
                            onClear: _billDate != null
                                ? () => setState(() => _billDate = null)
                                : null,
                          ),
                          const SizedBox(height: 14),
                          const _InputLabel('Claim Amount (LKR)'),
                          TextFormField(
                            controller: _amountController,
                            enabled: !busy,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Claim Amount',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              prefixText: 'LKR ',
                              hintText: '0.00',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Claim amount is required';
                              }
                              final parsed = double.tryParse(
                                value.replaceAll(',', '').trim(),
                              );
                              if (parsed == null || parsed <= 0) {
                                return 'Enter a valid amount greater than 0';
                              }
                              return null;
                            },
                          ),
                          if (_isOverBalance) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: MedicalClaimsColors.pendingBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Claim amount exceeds your remaining balance (${formatLkr(_currentPolicy.remainingBalanceLkr)}).',
                                style: const TextStyle(
                                  color: MedicalClaimsColors.pendingFg,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          const _InputLabel('What happened?'),
                          TextFormField(
                            controller: _descriptionController,
                            enabled: !busy,
                            maxLines: 3,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              labelText: 'Description / Notes',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              hintText:
                                  'Outpatient consultation, diagnosis, or hospital treatment details.',
                            ),
                            validator: (v) =>
                                (v == null || v.trim().length < 5)
                                ? 'Please enter at least 5 characters'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          MedicalBillUploadCard(
                            attachments: _attachments,
                            enabled: !busy,
                            onAttachmentAdded: (item) =>
                                setState(() => _attachments.add(item)),
                            onAttachmentRemoved: (idx) =>
                                setState(() => _attachments.removeAt(idx)),
                            onScanWithOcr: widget.onScanBillWithOcr != null
                                ? _scanWithOcr
                                : null,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'By submitting, you confirm that the information and documents provided are accurate.',
                            style: TextStyle(
                              color: MedicalClaimsColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: busy ? null : _submit,
                            icon: busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.chevron_right_rounded),
                            label: Text(
                              busy ? 'Submitting claim...' : 'Submit claim',
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: MedicalClaimsColors.navy,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InputLabel(label),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: onClear != null && enabled
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: onClear,
                    )
                  : const Icon(Icons.calendar_today_outlined, size: 17),
            ),
            child: Text(
              value ?? 'Select date',
              style: TextStyle(
                color: value == null
                    ? MedicalClaimsColors.textMuted
                    : MedicalClaimsColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
