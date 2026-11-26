import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../medical_claims/models/ocr_bill_data.dart';

/// Screen allowing the user to review, edit, and correct information
/// extracted from a medical bill before passing it to the claim form.
class OcrBillReviewScreen extends StatefulWidget {
  const OcrBillReviewScreen({
    super.key,
    required this.initialData,
    this.onRetake,
  });

  final OcrBillData initialData;
  final VoidCallback? onRetake;

  @override
  State<OcrBillReviewScreen> createState() => _OcrBillReviewScreenState();
}

class _OcrBillReviewScreenState extends State<OcrBillReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hospitalController;
  late final TextEditingController _billNumberController;
  late final TextEditingController _amountController;
  DateTime? _selectedBillDate;
  bool _showRawText = false;

  @override
  void initState() {
    super.initState();
    _hospitalController =
        TextEditingController(text: widget.initialData.hospitalName ?? '');
    _billNumberController =
        TextEditingController(text: widget.initialData.billNumber ?? '');
    _amountController = TextEditingController(
      text: widget.initialData.amount != null && widget.initialData.amount! > 0
          ? widget.initialData.amount!.toStringAsFixed(2)
          : '',
    );
    _selectedBillDate = widget.initialData.billDate;
  }

  @override
  void dispose() {
    _hospitalController.dispose();
    _billNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBillDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedBillDate = picked);
    }
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );

    final verifiedData = OcrBillData(
      hospitalName: _hospitalController.text.trim().isEmpty
          ? null
          : _hospitalController.text.trim(),
      billNumber: _billNumberController.text.trim().isEmpty
          ? null
          : _billNumberController.text.trim(),
      amount: parsedAmount,
      billDate: _selectedBillDate,
      localImagePath: widget.initialData.localImagePath,
      rawText: widget.initialData.rawText,
    );

    Navigator.of(context).pop(verifiedData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final imagePath = widget.initialData.localImagePath;
    final hasImage =
        imagePath != null && !kIsWeb && File(imagePath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Extracted Bill'),
        actions: [
          if (widget.onRetake != null)
            IconButton(
              tooltip: 'Retake / Re-scan',
              icon: const Icon(Icons.refresh),
              onPressed: widget.onRetake,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _onConfirm,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Apply to Claim'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner explaining user review
              Card(
                color: colors.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: colors.onPrimaryContainer,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI has scanned your bill. Please verify and correct any fields before applying to your claim.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Image preview section
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: colors.surfaceContainerHighest,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Chip(
                            backgroundColor: colors.surface.withValues(alpha: 0.85),
                            avatar: const Icon(Icons.receipt, size: 16),
                            label: const Text(
                              'Scanned Receipt',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Extracted editable fields
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extracted Bill Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Hospital Name
                      TextFormField(
                        controller: _hospitalController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Hospital / Clinic Name',
                          hintText: 'e.g. Asiri Hospital, Nawaloka',
                          prefixIcon: Icon(Icons.local_hospital_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().length < 2)
                                ? 'Please enter hospital name'
                                : null,
                      ),
                      const SizedBox(height: 14),

                      // Bill / Invoice Number
                      TextFormField(
                        controller: _billNumberController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Bill / Invoice Number',
                          hintText: 'e.g. INV-10928, BILL/2026/01',
                          prefixIcon: Icon(Icons.tag),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Please enter bill number'
                                : null,
                      ),
                      const SizedBox(height: 14),

                      // Bill Date
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Bill Date',
                            prefixIcon: const Icon(Icons.calendar_today_outlined),
                            border: const OutlineInputBorder(),
                            suffixIcon: _selectedBillDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () =>
                                        setState(() => _selectedBillDate = null),
                                  )
                                : null,
                          ),
                          child: Text(
                            _selectedBillDate != null
                                ? DateFormat('yyyy-MM-dd')
                                    .format(_selectedBillDate!)
                                : 'Select date from bill',
                            style: _selectedBillDate == null
                                ? theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )
                                : theme.textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Total Amount
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Total Bill Amount (LKR)',
                          hintText: 'e.g. 25000.00',
                          prefixIcon: Icon(Icons.payments_outlined),
                          prefixText: 'Rs. ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter total amount';
                          }
                          final parsed = double.tryParse(
                            value.replaceAll(',', '').trim(),
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Please enter a valid positive amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Expandable Raw Text View
              if (widget.initialData.rawText != null &&
                  widget.initialData.rawText!.trim().isNotEmpty) ...[
                Card(
                  child: ExpansionTile(
                    initiallyExpanded: _showRawText,
                    onExpansionChanged: (exp) =>
                        setState(() => _showRawText = exp),
                    leading: const Icon(Icons.text_snippet_outlined),
                    title: const Text('View Raw OCR Text'),
                    subtitle: const Text(
                      'Check raw text recognized directly from the image',
                      style: TextStyle(fontSize: 12),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          widget.initialData.rawText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
