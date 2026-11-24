import 'package:flutter/material.dart';

import '../models/claim.dart';
import '../services/claim_service.dart';

class SubmitClaimScreen extends StatefulWidget {
  const SubmitClaimScreen({super.key});

  @override
  State<SubmitClaimScreen> createState() => _SubmitClaimScreenState();
}

class _SubmitClaimScreenState extends State<SubmitClaimScreen> {
  final _formKey = GlobalKey<FormState>();

  final _policyIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedType = 'Motor Insurance';

  final List<String> _claimTypes = [
    'Motor Insurance',
    'Medical Insurance',
    'Life Insurance',
    'Travel Insurance',
  ];

  void _submitClaim() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) return;

    final claim = Claim(
      claimId: 'CLM-${DateTime.now().millisecondsSinceEpoch}',
      policyId: _policyIdController.text.trim(),
      claimType: _selectedType,
      description: _descriptionController.text.trim(),
      claimAmount: amount,
      status: 'Pending',
      submittedDate: DateTime.now(),
      documents: [],
    );

    ClaimService().addClaim(claim);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Claim submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _policyIdController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Submit New Claim'),
        backgroundColor: const Color(0xFF123B65),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Claim Information',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123B65),
                ),
              ),

              const SizedBox(height: 24),

              const Text('Insurance Type'),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _claimTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              const Text('Policy ID'),

              const SizedBox(height: 8),

              TextFormField(
                controller: _policyIdController,
                decoration: const InputDecoration(
                  hintText: 'Enter your policy ID',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your policy ID';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text('Claim Amount (LKR)'),

              const SizedBox(height: 8),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter claim amount',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter claim amount';
                  }

                  final amount = double.tryParse(value);

                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text('Description'),

              const SizedBox(height: 8),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe your claim...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF123B65),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit Claim',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
