import 'package:flutter/material.dart';

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
      '$policyId · $planName (Balance ${formatLkr(remainingBalanceLkr)})';
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
      planName: 'Family Health Plus',
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
  static const List<String> _commonHospitals = [
    'Asiri Hospital',
    'Nawaloka Hospital',
    'Lanka Hospitals',
    'Durdans Hospital',
    'Hemas Hospital',
  ];

  final _formKey = GlobalKey<FormState>();

  late final List<MedicalPolicyOption> _policyOptions;
  late String _selectedPolicyId;

  late final TextEditingController _patientNameController;
  late final TextEditingController _hospitalNameController;
  late final TextEditingController _billNumberController;
  late final TextEditingController _claimAmountController;
  late final TextEditingController _descriptionController;

  String _patientRelationship = MedicalClaim.relationships.first;
  String _treatmentType = MedicalClaim.treatmentTypes.first;
  DateTime _admissionDate = DateTime.now();
  DateTime? _dischargeDate;
  DateTime? _billDate;
  String? _localBillFilePath;
  bool _ocrApplied = false;
  double? _enteredAmount;

  MedicalPolicyOption get _selectedPolicy => _policyOptions.firstWhere(
    (option) => option.policyId == _selectedPolicyId,
    orElse: () => _policyOptions.first,
  );

  bool get _exceedsPolicyBalance =>
      _enteredAmount != null &&
      _enteredAmount! > _selectedPolicy.remainingBalanceLkr;

  @override
  void initState() {
    super.initState();
    _policyOptions = List<MedicalPolicyOption>.from(
      SubmitMedicalClaimScreen.defaultPolicies,
    );
    final requestedPolicy = widget.initialPolicyId?.trim();
    if (requestedPolicy != null && requestedPolicy.isNotEmpty) {
      final exists = _policyOptions.any(
        (option) => option.policyId == requestedPolicy,
      );
      if (!exists) {
        _policyOptions.insert(
          0,
          MedicalPolicyOption(
            policyId: requestedPolicy,
            planName: 'Active Medical Policy',
            remainingBalanceLkr: 250000.00,
          ),
        );
      }
      _selectedPolicyId = requestedPolicy;
    } else {
      _selectedPolicyId = _policyOptions.first.policyId;
    }

    _patientNameController = TextEditingController();
    _hospitalNameController = TextEditingController();
    _billNumberController = TextEditingController();
    _claimAmountController = TextEditingController();
    _descriptionController = TextEditingController();

    _claimAmountController.addListener(_onAmountChanged);

    if (widget.ocrPrefill != null) {
      _applyOcrPrefill(widget.ocrPrefill!, showSnackbar: false);
    }
  }

  @override
  void dispose() {
    _claimAmountController.removeListener(_onAmountChanged);
    _patientNameController.dispose();
    _hospitalNameController.dispose();
    _billNumberController.dispose();
    _claimAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final parsed = double.tryParse(
      _claimAmountController.text.replaceAll(',', '').trim(),
    );
    if (parsed != _enteredAmount) {
      setState(() => _enteredAmount = parsed);
    }
  }

  void _applyOcrPrefill(OcrBillData data, {bool showSnackbar = true}) {
    if (data.hospitalName != null && data.hospitalName!.trim().isNotEmpty) {
      _hospitalNameController.text = data.hospitalName!.trim();
    }
    if (data.billNumber != null && data.billNumber!.trim().isNotEmpty) {
      _billNumberController.text = data.billNumber!.trim();
    }
    if (data.amount != null && data.amount! > 0) {
      _claimAmountController.text = data.amount!.toStringAsFixed(2);
      _enteredAmount = data.amount;
    }
    if (data.billDate != null) {
      _billDate = data.billDate;
    }
    if (data.hasImage) {
      _localBillFilePath = data.localImagePath;
    }
    _ocrApplied = data.hasExtractedFields || data.hasImage;

    if (showSnackbar && mounted) {
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

  Future<void> _handleScanWithOcr() async {
    final scanner = widget.onScanBillWithOcr;
    if (scanner == null) return;
    final extracted = await scanner(context);
    if (extracted != null && mounted) {
      _applyOcrPrefill(extracted);
    }
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onSelected,
    DateTime? firstDate,
  }) async {
    final now = DateTime.now();
    final earliest = firstDate ?? DateTime(now.year - 2);
    final candidate = current ?? now;
    final initial = candidate.isBefore(earliest)
        ? earliest
        : (candidate.isAfter(now) ? now : candidate);

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: earliest,
      lastDate: now,
    );
    if (selected != null && mounted) {
      setState(() => onSelected(selected));
    }
  }

  Future<void> _submitForm() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (_dischargeDate != null && _dischargeDate!.isBefore(_admissionDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Discharge date cannot be earlier than the admission/visit date.',
          ),
        ),
      );
      return;
    }

    final parsedAmount = double.tryParse(
      _claimAmountController.text.replaceAll(',', '').trim(),
    );
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid claim amount in LKR.'),
        ),
      );
      return;
    }

    final createdClaim = await widget.service.submitMedicalClaim(
      userId: widget.userId,
      policyId: _selectedPolicyId,
      claimAmount: parsedAmount,
      description: _descriptionController.text,
      patientName: _patientNameController.text,
      patientRelationship: _patientRelationship,
      hospitalName: _hospitalNameController.text,
      treatmentType: _treatmentType,
      admissionDate: _admissionDate,
      dischargeDate: _dischargeDate,
      billNumber: _billNumberController.text,
      billDate: _billDate,
      localBillFilePath: _localBillFilePath,
    );

    if (!mounted) return;

    if (createdClaim != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Medical claim ${createdClaim.claimId} submitted successfully.',
          ),
        ),
      );
      Navigator.of(context).pop(createdClaim);
    } else {
      final message =
          widget.service.errorMessage ?? 'Unable to submit medical claim.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dates = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Medical Claim')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.service,
          builder: (context, _) {
            final isSubmitting = widget.service.isSubmitting;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_ocrApplied) ...[
                          Card(
                            color: colors.secondaryContainer,
                            child: ListTile(
                              leading: Icon(
                                Icons.auto_awesome_outlined,
                                color: colors.onSecondaryContainer,
                              ),
                              title: Text(
                                'Auto-filled from AI Bill OCR — please verify details',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colors.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Review hospital, bill number, date, and amount before submitting.',
                                style: TextStyle(
                                  color: colors.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _FormSectionCard(
                          title: 'Medical Policy',
                          icon: Icons.verified_user_outlined,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedPolicyId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Select Active Medical Policy',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final option in _policyOptions)
                                  DropdownMenuItem(
                                    value: option.policyId,
                                    child: Text(
                                      option.displayLabel,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: isSubmitting
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(
                                          () => _selectedPolicyId = value,
                                        );
                                      }
                                    },
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'Please select a medical policy'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryContainer.withValues(
                                  alpha: 0.45,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 18,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Available Balance: ${formatLkr(_selectedPolicy.remainingBalanceLkr)}',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: colors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _FormSectionCard(
                          title: 'Patient Information',
                          icon: Icons.person_outline,
                          children: [
                            TextFormField(
                              controller: _patientNameController,
                              enabled: !isSubmitting,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Patient Name',
                                hintText: 'e.g. Kasun Perera',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'Patient name is required'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _patientRelationship,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Relationship',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final relationship
                                    in MedicalClaim.relationships)
                                  DropdownMenuItem(
                                    value: relationship,
                                    child: Text(relationship),
                                  ),
                              ],
                              onChanged: isSubmitting
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(
                                          () => _patientRelationship = value,
                                        );
                                      }
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _FormSectionCard(
                          title: 'Hospital & Treatment Information',
                          icon: Icons.local_hospital_outlined,
                          children: [
                            TextFormField(
                              controller: _hospitalNameController,
                              enabled: !isSubmitting,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Hospital Name',
                                hintText: 'e.g. Asiri Hospital',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'Hospital name is required'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                for (final hospital in _commonHospitals)
                                  ActionChip(
                                    label: Text(hospital),
                                    onPressed: isSubmitting
                                        ? null
                                        : () => setState(
                                            () => _hospitalNameController.text =
                                                hospital,
                                          ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _treatmentType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Treatment Type',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final type in MedicalClaim.treatmentTypes)
                                  DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                              ],
                              onChanged: isSubmitting
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _treatmentType = value);
                                      }
                                    },
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final admissionPicker = _DateField(
                                  label: 'Admission / Visit Date',
                                  dateText: dates.formatMediumDate(
                                    _admissionDate,
                                  ),
                                  enabled: !isSubmitting,
                                  onTap: () => _pickDate(
                                    current: _admissionDate,
                                    onSelected: (date) {
                                      _admissionDate = date;
                                      if (_dischargeDate != null &&
                                          _dischargeDate!.isBefore(date)) {
                                        _dischargeDate = null;
                                      }
                                    },
                                  ),
                                );
                                final dischargePicker = _DateField(
                                  label: 'Discharge Date (Optional)',
                                  dateText: _dischargeDate != null
                                      ? dates.formatMediumDate(_dischargeDate!)
                                      : null,
                                  enabled: !isSubmitting,
                                  onTap: () => _pickDate(
                                    current: _dischargeDate ?? _admissionDate,
                                    firstDate: _admissionDate,
                                    onSelected: (date) => _dischargeDate = date,
                                  ),
                                  onClear: _dischargeDate != null
                                      ? () => setState(
                                          () => _dischargeDate = null,
                                        )
                                      : null,
                                );

                                if (constraints.maxWidth >= 480) {
                                  return Row(
                                    children: [
                                      Expanded(child: admissionPicker),
                                      const SizedBox(width: 12),
                                      Expanded(child: dischargePicker),
                                    ],
                                  );
                                }
                                return Column(
                                  children: [
                                    admissionPicker,
                                    const SizedBox(height: 12),
                                    dischargePicker,
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _FormSectionCard(
                          title: 'Bill Details',
                          icon: Icons.receipt_outlined,
                          children: [
                            TextFormField(
                              controller: _billNumberController,
                              enabled: !isSubmitting,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Bill Number (Optional)',
                                hintText: 'e.g. ASH-2026-88412',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _DateField(
                              label: 'Bill Date (Optional)',
                              dateText: _billDate != null
                                  ? dates.formatMediumDate(_billDate!)
                                  : null,
                              enabled: !isSubmitting,
                              onTap: () => _pickDate(
                                current: _billDate,
                                onSelected: (date) => _billDate = date,
                              ),
                              onClear: _billDate != null
                                  ? () => setState(() => _billDate = null)
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _claimAmountController,
                              enabled: !isSubmitting,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Claim Amount',
                                prefixText: 'LKR ',
                                hintText: '0.00',
                                border: OutlineInputBorder(),
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
                            if (_exceedsPolicyBalance) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colors.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 20,
                                      color: colors.onTertiaryContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Claim amount exceeds your remaining balance (${formatLkr(_selectedPolicy.remainingBalanceLkr)}) on ${_selectedPolicy.policyId}. Excess costs may require co-payment.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colors.onTertiaryContainer,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _descriptionController,
                              enabled: !isSubmitting,
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: 'Description / Notes',
                                hintText:
                                    'Summarize diagnosis, consultation, lab tests, or procedures.',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().length < 5)
                                  ? 'Please enter at least 5 characters'
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        MedicalBillUploadCard(
                          selectedFilePath: _localBillFilePath,
                          enabled: !isSubmitting,
                          onFileSelected: (path) =>
                              setState(() => _localBillFilePath = path),
                          onScanWithOcr: widget.onScanBillWithOcr != null
                              ? _handleScanWithOcr
                              : null,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: isSubmitting ? null : _submitForm,
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label: Text(
                            isSubmitting
                                ? 'Submitting claim...'
                                : 'Submit Medical Claim',
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.dateText,
    required this.enabled,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String? dateText;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: onClear != null && enabled
              ? IconButton(
                  tooltip: 'Clear date',
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          dateText ?? 'Select date',
          style: dateText == null
              ? theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
