import 'package:flutter/material.dart';

import '../models/medical_claim.dart';
import '../models/ocr_bill_data.dart';
import '../services/medical_claim_service.dart';
import '../widgets/bill_upload_picker.dart';

typedef OcrBillScannerCallback = Future<OcrBillData?> Function(
  BuildContext context,
);

class SubmitMedicalClaimScreen extends StatefulWidget {
  const SubmitMedicalClaimScreen({
    super.key,
    required this.service,
    this.initialOcrData,
    this.defaultPolicyId = 'MEDICAL-001',
    this.onScanBillWithOcr,
  });

  final MedicalClaimService service;
  final OcrBillData? initialOcrData;
  final String defaultPolicyId;
  final OcrBillScannerCallback? onScanBillWithOcr;

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

  late final TextEditingController _policyIdController;
  late final TextEditingController _patientNameController;
  late final TextEditingController _hospitalNameController;
  late final TextEditingController _billNumberController;
  late final TextEditingController _claimAmountController;
  late final TextEditingController _descriptionController;

  String _patientRelationship = MedicalClaim.relationships.first;
  String _treatmentType = MedicalClaim.treatmentTypes.first;
  DateTime? _admissionDate;
  DateTime? _dischargeDate;
  DateTime? _billDate;
  String? _localBillFilePath;
  bool _ocrApplied = false;

  @override
  void initState() {
    super.initState();
    _policyIdController = TextEditingController(text: widget.defaultPolicyId);
    _patientNameController = TextEditingController();
    _hospitalNameController = TextEditingController();
    _billNumberController = TextEditingController();
    _claimAmountController = TextEditingController();
    _descriptionController = TextEditingController();

    if (widget.initialOcrData != null) {
      _applyOcrData(widget.initialOcrData!, notify: false);
    }
  }

  @override
  void dispose() {
    _policyIdController.dispose();
    _patientNameController.dispose();
    _hospitalNameController.dispose();
    _billNumberController.dispose();
    _claimAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyOcrData(OcrBillData data, {bool notify = true}) {
    if (data.hospitalName != null && data.hospitalName!.trim().isNotEmpty) {
      _hospitalNameController.text = data.hospitalName!.trim();
    }
    if (data.billNumber != null && data.billNumber!.trim().isNotEmpty) {
      _billNumberController.text = data.billNumber!.trim();
    }
    if (data.amount != null && data.amount! > 0) {
      _claimAmountController.text = data.amount!.toStringAsFixed(2);
    }
    if (data.billDate != null) {
      _billDate = data.billDate;
    }
    if (data.hasImage) {
      _localBillFilePath = data.localImagePath;
    }
    _ocrApplied = data.hasExtractedFields || data.hasImage;

    if (notify && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Medical bill details auto-filled from OCR. Please review before submitting.',
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
      _applyOcrData(extracted);
    }
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onSelected,
    DateTime? firstDate,
  }) async {
    final now = DateTime.now();
    final initial = current ?? now;
    final earliest = firstDate ?? DateTime(now.year - 2);
    final clampedInitial = initial.isBefore(earliest)
        ? earliest
        : (initial.isAfter(now) ? now : initial);

    final selected = await showDatePicker(
      context: context,
      initialDate: clampedInitial,
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

    if (_admissionDate != null &&
        _dischargeDate != null &&
        _dischargeDate!.isBefore(_admissionDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discharge date cannot be earlier than admission date.'),
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
      policyId: _policyIdController.text,
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
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_ocrApplied)
                        Card(
                          color: colors.secondaryContainer,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: Icon(
                              Icons.document_scanner_outlined,
                              color: colors.onSecondaryContainer,
                            ),
                            title: Text(
                              'Auto-filled from AI Bill OCR',
                              style: TextStyle(
                                color: colors.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Review and edit any extracted fields before submitting your claim.',
                              style: TextStyle(
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ),
                      if (widget.onScanBillWithOcr != null) ...[
                        FilledButton.tonalIcon(
                          onPressed: isSubmitting ? null : _handleScanWithOcr,
                          icon: const Icon(Icons.document_scanner_outlined),
                          label: Text(
                            _ocrApplied
                                ? 'Rescan medical bill with AI OCR'
                                : 'Scan medical bill with AI OCR',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _SectionCard(
                        title: 'Policy & Patient Information',
                        icon: Icons.person_outline,
                        children: [
                          TextFormField(
                            controller: _policyIdController,
                            enabled: !isSubmitting,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Medical Policy ID',
                              hintText: 'e.g. MEDICAL-001',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Policy ID is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _patientNameController,
                            enabled: !isSubmitting,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Patient Full Name',
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
                            decoration: const InputDecoration(
                              labelText: 'Relationship to Policyholder',
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
                      _SectionCard(
                        title: 'Hospital & Treatment Details',
                        icon: Icons.local_hospital_outlined,
                        children: [
                          TextFormField(
                            controller: _hospitalNameController,
                            enabled: !isSubmitting,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Hospital / Clinic Name',
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
                                      : () {
                                          setState(() {
                                            _hospitalNameController.text =
                                                hospital;
                                          });
                                        },
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _treatmentType,
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
                              final admissionField = _DatePickerField(
                                label: _treatmentType == 'Inpatient'
                                    ? 'Admission Date'
                                    : 'Admission Date (Optional)',
                                dateText: _admissionDate != null
                                    ? dates.formatMediumDate(_admissionDate!)
                                    : null,
                                enabled: !isSubmitting,
                                onTap: () => _pickDate(
                                  current: _admissionDate,
                                  onSelected: (date) => _admissionDate = date,
                                ),
                                onClear: _admissionDate != null
                                    ? () => setState(() => _admissionDate = null)
                                    : null,
                              );
                              final dischargeField = _DatePickerField(
                                label: _treatmentType == 'Inpatient'
                                    ? 'Discharge Date'
                                    : 'Discharge Date (Optional)',
                                dateText: _dischargeDate != null
                                    ? dates.formatMediumDate(_dischargeDate!)
                                    : null,
                                enabled: !isSubmitting,
                                onTap: () => _pickDate(
                                  current: _dischargeDate,
                                  firstDate: _admissionDate,
                                  onSelected: (date) => _dischargeDate = date,
                                ),
                                onClear: _dischargeDate != null
                                    ? () => setState(() => _dischargeDate = null)
                                    : null,
                              );

                              if (constraints.maxWidth >= 460) {
                                return Row(
                                  children: [
                                    Expanded(child: admissionField),
                                    const SizedBox(width: 12),
                                    Expanded(child: dischargeField),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  admissionField,
                                  const SizedBox(height: 12),
                                  dischargeField,
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Bill & Claim Information',
                        icon: Icons.receipt_outlined,
                        children: [
                          TextFormField(
                            controller: _billNumberController,
                            enabled: !isSubmitting,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Bill / Invoice Number (Optional)',
                              hintText: 'e.g. ASH-2026-88412',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DatePickerField(
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
                            keyboardType: const TextInputType.numberWithOptions(
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
                                return 'Enter an amount greater than 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _descriptionController,
                            enabled: !isSubmitting,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Diagnosis / Treatment Description',
                              hintText:
                                  'Describe the consultation, procedure, or lab tests covered by this bill.',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            validator: (value) =>
                                (value == null || value.trim().length < 5)
                                ? 'Please enter a short description (at least 5 characters)'
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BillUploadPicker(
                        selectedFilePath: _localBillFilePath,
                        enabled: !isSubmitting,
                        onFileSelected: (path) =>
                            setState(() => _localBillFilePath = path),
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
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
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
              ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
