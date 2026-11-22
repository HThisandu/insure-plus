import 'package:flutter/material.dart';
import '../models/motor_claim.dart';
import '../services/motor_claim_service.dart';

/// Screen allowing users to edit editable details of an existing Motor Claim.
class EditMotorClaimScreen extends StatefulWidget {
  final MotorClaim claim;

  const EditMotorClaimScreen({
    super.key,
    required this.claim,
  });

  @override
  State<EditMotorClaimScreen> createState() => _EditMotorClaimScreenState();
}

class _EditMotorClaimScreenState extends State<EditMotorClaimScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _contactNumberController;
  late TextEditingController _claimAmountController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _driverNameController;
  late TextEditingController _notesController;

  late String _damageSeverity;
  late bool _isVehicleDrivable;

  final List<String> _severities = ['Minor', 'Moderate', 'Severe'];

  @override
  void initState() {
    super.initState();
    _contactNumberController = TextEditingController(text: widget.claim.contactNumber);
    _claimAmountController = TextEditingController(text: widget.claim.claimAmount.toStringAsFixed(2));
    _descriptionController = TextEditingController(text: widget.claim.description);
    _locationController = TextEditingController(text: widget.claim.incidentLocation);
    _driverNameController = TextEditingController(text: widget.claim.driverName);
    _notesController = TextEditingController(text: widget.claim.notes ?? '');

    _damageSeverity = widget.claim.damageSeverity;
    _isVehicleDrivable = widget.claim.isVehicleDrivable;
  }

  @override
  void dispose() {
    _contactNumberController.dispose();
    _claimAmountController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _driverNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_claimAmountController.text.trim()) ?? widget.claim.claimAmount;

    final updatedClaim = widget.claim.copyWith(
      contactNumber: _contactNumberController.text.trim(),
      claimAmount: amount,
      description: _descriptionController.text.trim(),
      incidentLocation: _locationController.text.trim(),
      driverName: _driverNameController.text.trim(),
      damageSeverity: _damageSeverity,
      isVehicleDrivable: _isVehicleDrivable,
      notes: _notesController.text.trim().isEmpty ? widget.claim.notes : _notesController.text.trim(),
    );

    MotorClaimService().updateClaim(updatedClaim);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Claim details updated & synced to Firebase!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Claim: ${widget.claim.claimId}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Vehicle & Policy Info Banner (Read-only)
            Card(
              color: Colors.indigo.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.claim.vehicleDisplayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Policy ID: ${widget.claim.policyId}  •  Status: ${widget.claim.status.value}',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Editable Fields
            TextFormField(
              controller: _contactNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Contact number required';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _driverNameController,
              decoration: const InputDecoration(
                labelText: 'Driver Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Driver name required';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Incident Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Location required';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _claimAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Claim Amount (\$) [Shared]',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Cost required';
                      }
                      final n = double.tryParse(val.trim());
                      if (n == null || n <= 0) {
                        return 'Must be positive';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _damageSeverity,
                    decoration: const InputDecoration(labelText: 'Damage Severity'),
                    items: _severities
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _damageSeverity = val);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Is the vehicle drivable?'),
              subtitle: Text(_isVehicleDrivable ? 'Yes, roadworthy' : 'No, immobilized'),
              value: _isVehicleDrivable,
              onChanged: (val) => setState(() => _isVehicleDrivable = val),
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Damage & Incident Description [Shared]',
                alignLabelWithHint: true,
              ),
              validator: (val) {
                if (val == null || val.trim().length < 5) {
                  return 'Description too short';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Additional Notes or Remarks',
                hintText: 'e.g. Preferred repair workshop name or repair slot',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _handleSave,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save & Sync Changes', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
