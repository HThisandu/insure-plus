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
  final List<PendingMedicalAttachment> _attachments = [];
  bool _ocrApplied = false;
  double? _enteredAmount;
  int _descriptionLength = 0;

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
            planName: 'Health Plus',
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
    _descriptionController.addListener(_onDescriptionChanged);

    if (widget.ocrPrefill != null) {
      _applyOcrPrefill(widget.ocrPrefill!, showSnackbar: false);
    }
  }

  @override
  void dispose() {
    _claimAmountController.removeListener(_onAmountChanged);
    _descriptionController.removeListener(_onDescriptionChanged);
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

  void _onDescriptionChanged() {
    final len = _descriptionController.text.length;
    if (len != _descriptionLength) {
      setState(() => _descriptionLength = len);
    }
  }

  String _fileNameFromPath(String path) {
    final segments = path
        .split(RegExp(r'[/\\]'))
        .where((part) => part.isNotEmpty)
        .toList();
    return segments.isNotEmpty ? segments.last : path;
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
      final path = data.localImagePath!.trim();
      final alreadyAdded = _attachments.any((item) => item.localPath == path);
      if (!alreadyAdded) {
        _attachments.add(
          PendingMedicalAttachment(
            fileName: _fileNameFromPath(path),
            documentType: 'Medical Bill',
            localPath: path,
          ),
        );
      }
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
      attachments: List<PendingMedicalAttachment>.from(_attachments),
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
              final isSubmitting = widget.service.isSubmitting;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
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
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: MedicalClaimsColors.successBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_outlined,
                                    color: MedicalClaimsColors.successFg,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Auto-filled from AI Bill OCR — please verify details',
                                      style: TextStyle(
                                        color: MedicalClaimsColors.successFg,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          const _FieldLabel('Claim type'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: MedicalClaimsColors.border,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Health / Medical insurance',
                                    style: TextStyle(
                                      color: MedicalClaimsColors.textPrimary,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: MedicalClaimsColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel('Select policy'),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPolicyId,
                            isExpanded: true,
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
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final patientField = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _FieldLabel('Patient Name'),
                                  TextFormField(
                                    controller: _patientNameController,
                                    enabled: !isSubmitting,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Patient Name',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      hintText: 'e.g. Kasun Perera',
                                    ),
                                    validator: (value) =>
                                        (value == null || value.trim().isEmpty)
                                        ? 'Patient name is required'
                                        : null,
                                  ),
                                ],
                              );
                              final relationshipField = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _FieldLabel('Relationship'),
                                  DropdownButtonFormField<String>(
                                    initialValue: _patientRelationship,
                                    isExpanded: true,
                                    items: [
                                      for (final rel
                                          in MedicalClaim.relationships)
                                        DropdownMenuItem(
                                          value: rel,
                                          child: Text(rel),
                                        ),
                                    ],
                                    onChanged: isSubmitting
                                        ? null
                                        : (value) {
                                            if (value != null) {
                                              setState(
                                                () =>
                                                    _patientRelationship =
                                                        value,
                                              );
                                            }
                                          },
                                  ),
                                ],
                              );

                              if (constraints.maxWidth >= 480) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 3, child: patientField),
                                    const SizedBox(width: 12),
                                    Expanded(flex: 2, child: relationshipField),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  patientField,
                                  const SizedBox(height: 14),
                                  relationshipField,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel('Hospital Name'),
                          TextFormField(
                            controller: _hospitalNameController,
                            enabled: !isSubmitting,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Hospital Name',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              hintText: 'e.g. Asiri Hospital',
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Hospital name is required'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final hospital in _commonHospitals)
                                ActionChip(
                                  label: Text(
                                    hospital,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: MedicalClaimsColors.border,
                                  ),
                                  visualDensity: VisualDensity.compact,
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
                          const _FieldLabel('Treatment Type'),
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
                              final admissionField = _DateField(
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
                              final dischargeField = _DateField(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: admissionField),
                                    const SizedBox(width: 12),
                                    Expanded(child: dischargeField),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  admissionField,
                                  const SizedBox(height: 14),
                                  dischargeField,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final billNumberField = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const _FieldLabel('Bill Number (Optional)'),
                                  TextFormField(
                                    controller: _billNumberController,
                                    enabled: !isSubmitting,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Bill Number (Optional)',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      hintText: 'e.g. ASH-2026-88412',
                                    ),
                                  ),
                                ],
                              );
                              final billDateField = _DateField(
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
                              );

                              if (constraints.maxWidth >= 480) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: billNumberField),
                                    const SizedBox(width: 12),
                                    Expanded(child: billDateField),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  billNumberField,
                                  const SizedBox(height: 14),
                                  billDateField,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel('Claim Amount (LKR)'),
                          TextFormField(
                            controller: _claimAmountController,
                            enabled: !isSubmitting,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
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
                          if (_exceedsPolicyBalance) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: MedicalClaimsColors.pendingBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 19,
                                    color: MedicalClaimsColors.pendingFg,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Claim amount exceeds your remaining balance (${formatLkr(_selectedPolicy.remainingBalanceLkr)}) on ${_selectedPolicy.policyId}.',
                                      style: const TextStyle(
                                        color: MedicalClaimsColors.pendingFg,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          const _FieldLabel('What happened?'),
                          TextFormField(
                            controller: _descriptionController,
                            enabled: !isSubmitting,
                            maxLines: 3,
                            maxLength: 500,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Description / Notes',
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              hintText:
                                  'Outpatient consultation, diagnosis, or hospital treatment details.',
                              counterText: '$_descriptionLength / 500',
                            ),
                            validator: (value) =>
                                (value == null || value.trim().length < 5)
                                ? 'Please enter at least 5 characters'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          MedicalBillUploadCard(
                            attachments: _attachments,
                            enabled: !isSubmitting,
                            onAttachmentAdded: (item) =>
                                setState(() => _attachments.add(item)),
                            onAttachmentRemoved: (index) =>
                                setState(() => _attachments.removeAt(index)),
                            onScanWithOcr: widget.onScanBillWithOcr != null
                                ? _handleScanWithOcr
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
                            onPressed: isSubmitting ? null : _submitForm,
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                  ),
                            label: Text(
                              isSubmitting
                                  ? 'Submitting claim...'
                                  : 'Submit claim',
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              suffixIcon: onClear != null && enabled
                  ? IconButton(
                      tooltip: 'Clear date',
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: onClear,
                    )
                  : const Icon(
                      Icons.calendar_today_outlined,
                      size: 17,
                      color: MedicalClaimsColors.textSecondary,
                    ),
            ),
            child: Text(
              dateText ?? 'Select date',
              style: TextStyle(
                color: dateText == null
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
