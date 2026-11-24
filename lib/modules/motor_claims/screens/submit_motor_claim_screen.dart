import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../common/models/claim_document.dart';
import '../../../common/models/claim_status.dart';
import '../models/motor_claim.dart';
import '../services/firebase_auth_service.dart';
import '../services/motor_claim_service.dart';
import '../services/motor_claim_storage_service.dart';
import '../../../common/theme/insurecare_theme.dart';
import 'motor_claim_details_screen.dart';

/// Screen allowing users to file/submit a comprehensive new motor insurance claim.
/// Adheres strictly to the shared schema (claimId, userId, policyId, claimType,
/// claimAmount, description, status, documents, createdAt) where each document
/// contains (documentId, documentType, fileName, fileUrl, uploadedAt).
class SubmitMotorClaimScreen extends StatefulWidget {
  const SubmitMotorClaimScreen({super.key});

  @override
  State<SubmitMotorClaimScreen> createState() => _SubmitMotorClaimScreenState();
}

class _SubmitMotorClaimScreenState extends State<SubmitMotorClaimScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared Core Claim Fields
  final _userIdController = TextEditingController();
  final _policyIdController = TextEditingController(text: 'POL-MOT-');
  final _claimantNameController = TextEditingController();
  final _contactNumberController = TextEditingController();

  // Vehicle Information
  final _vehicleRegController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  int _vehicleYear = 2022;
  String _vehicleType = 'Car';

  // Incident & Accident Information
  DateTime _incidentDate = DateTime.now();
  TimeOfDay _incidentTime = TimeOfDay.now();
  final _incidentLocationController = TextEditingController();
  String _incidentType = 'Collision';
  String _damageSeverity = 'Moderate';
  bool _isVehicleDrivable = true;
  bool _policeReportFiled = false;
  final _policeReportNumberController = TextEditingController();

  // Driver Information
  final _driverNameController = TextEditingController();
  final _driverLicenseController = TextEditingController();
  String _relationshipToInsured = 'Self';

  // Third-Party Information
  bool _thirdPartyInvolved = false;
  final _thirdPartyNameController = TextEditingController();
  final _thirdPartyVehicleController = TextEditingController();
  final _thirdPartyContactController = TextEditingController();
  final _thirdPartyInsuranceController = TextEditingController();

  // Financial & Loss Description
  final _claimAmountController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Actual files selected by the user. File bytes are uploaded to Storage.
  final List<PlatformFile> _selectedAccidentPhotos = [];
  final List<PlatformFile> _selectedSupportingFiles = [];

  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  final List<String> _vehicleTypes = [
    'Car',
    'SUV',
    'Motorcycle',
    'Van',
    'Commercial / Truck',
  ];
  final List<String> _incidentTypes = [
    'Collision',
    'Single Vehicle Accident',
    'Hit and Run / Parked Vehicle Damage',
    'Natural Disaster',
    'Fire Damage',
    'Theft / Break-in',
    'Vandalism',
  ];
  final List<String> _severities = ['Minor', 'Moderate', 'Severe'];
  final List<String> _relationships = [
    'Self',
    'Spouse',
    'Son / Daughter',
    'Employee',
    'Authorized Driver',
  ];

  @override
  void dispose() {
    _userIdController.dispose();
    _policyIdController.dispose();
    _claimantNameController.dispose();
    _contactNumberController.dispose();
    _vehicleRegController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _incidentLocationController.dispose();
    _policeReportNumberController.dispose();
    _driverNameController.dispose();
    _driverLicenseController.dispose();
    _thirdPartyNameController.dispose();
    _thirdPartyVehicleController.dispose();
    _thirdPartyContactController.dispose();
    _thirdPartyInsuranceController.dispose();
    _claimAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectIncidentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _incidentDate = picked;
      });
    }
  }

  Future<void> _selectIncidentTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _incidentTime,
    );
    if (picked != null) {
      setState(() {
        _incidentTime = picked;
      });
    }
  }

  // Select one file per tap; tap again to add more files.
  Future<void> _pickAccidentPhotos() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (!mounted || file == null) return;
    final size = await file.length();
    if (!mounted) return;
    if (size == null || size > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each photo must be 10 MB or smaller.')),
      );
      return;
    }
    setState(() {
      if (!_selectedAccidentPhotos.any((item) => item.name == file.name)) {
        _selectedAccidentPhotos.add(file);
      }
    });
  }

  Future<void> _pickSupportingDocuments() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (!mounted || file == null) return;
    final size = await file.length();
    if (!mounted) return;
    if (size == null || size > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Each document must be 10 MB or smaller.'),
        ),
      );
      return;
    }
    setState(() {
      if (!_selectedSupportingFiles.any((item) => item.name == file.name)) {
        _selectedSupportingFiles.add(file);
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please correct the errors in the form before submitting.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedAccidentPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one accident photo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the declaration checkbox to continue.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final incidentTimeText = _incidentTime.format(context);
    setState(() => _isSubmitting = true);
    try {
      final user = await FirebaseAuthService.instance.ensureSignedIn();
      _userIdController.text = user.uid;
      final claimService = MotorClaimService();
      final newClaimId = claimService.generateNextClaimId();
      final storageService = MotorClaimStorageService.instance;
      final uploadedDocuments = <ClaimDocument>[];

      for (final photo in _selectedAccidentPhotos) {
        uploadedDocuments.add(
          await storageService.uploadClaimFile(
            userId: user.uid,
            claimId: newClaimId,
            file: photo,
            documentType: 'AccidentPhoto',
          ),
        );
      }
      for (final document in _selectedSupportingFiles) {
        uploadedDocuments.add(
          await storageService.uploadClaimFile(
            userId: user.uid,
            claimId: newClaimId,
            file: document,
            documentType: 'SupportingDocument',
          ),
        );
      }

      final newClaim = MotorClaim(
        claimId: newClaimId,
        userId: user.uid,
        policyId: _policyIdController.text.trim(),
        claimType: 'Motor Claim',
        claimAmount: double.parse(_claimAmountController.text.trim()),
        description: _descriptionController.text.trim(),
        status: ClaimStatus.submitted,
        documents: uploadedDocuments,
        createdAt: DateTime.now(),
        claimantName: _claimantNameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        vehicleRegistrationNumber: _vehicleRegController.text
            .trim()
            .toUpperCase(),
        vehicleMake: _vehicleMakeController.text.trim(),
        vehicleModel: _vehicleModelController.text.trim(),
        vehicleYear: _vehicleYear,
        vehicleType: _vehicleType,
        incidentDate: _incidentDate,
        incidentTime: incidentTimeText,
        incidentLocation: _incidentLocationController.text.trim(),
        incidentType: _incidentType,
        damageSeverity: _damageSeverity,
        isVehicleDrivable: _isVehicleDrivable,
        policeReportFiled: _policeReportFiled,
        policeReportNumber: _policeReportFiled
            ? _policeReportNumberController.text.trim()
            : null,
        driverName: _driverNameController.text.trim().isEmpty
            ? _claimantNameController.text.trim()
            : _driverNameController.text.trim(),
        driverLicenseNumber: _driverLicenseController.text.trim(),
        relationshipToInsured: _relationshipToInsured,
        thirdPartyInvolved: _thirdPartyInvolved,
        thirdPartyName: _thirdPartyInvolved
            ? _thirdPartyNameController.text.trim()
            : null,
        thirdPartyVehicleNumber: _thirdPartyInvolved
            ? _thirdPartyVehicleController.text.trim().toUpperCase()
            : null,
        thirdPartyContact: _thirdPartyInvolved
            ? _thirdPartyContactController.text.trim()
            : null,
        thirdPartyInsurance: _thirdPartyInvolved
            ? _thirdPartyInsuranceController.text.trim()
            : null,
        notes: 'Submitted through the Insure-Plus mobile application.',
      );

      await claimService.addClaim(newClaim);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Claim Submitted!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your claim details and documents were saved to Supabase.',
              ),
              const SizedBox(height: 12),
              Text('Claim reference: $newClaimId'),
              Text('Files uploaded: ${uploadedDocuments.length}'),
              Text('Status: ${ClaimStatus.submitted.value}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Return to Portal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MotorClaimDetailsScreen(claimId: newClaimId),
                  ),
                );
              },
              child: const Text('View Claim Details'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claim submission failed: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted && _isSubmitting) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: InsureCareTheme.border, width: 0.7),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: InsureCareTheme.paleBlue,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: InsureCareTheme.iconBlue, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: InsureCareTheme.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay =
        '${_incidentDate.year}-${_incidentDate.month.toString().padLeft(2, '0')}-${_incidentDate.day.toString().padLeft(2, '0')}';
    final timeDisplay =
        '${_incidentTime.hour.toString().padLeft(2, '0')}:${_incidentTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Submit a claim')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Let's get you covered.",
                    style: TextStyle(
                      color: InsureCareTheme.navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Submit your motor claim in a few simple steps.',
                    style: TextStyle(
                      color: InsureCareTheme.muted,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 15),
                  _ClaimFormTip(),
                ],
              ),
            ),
            // Section 1: Policy & Claimant Details (Shared Schema)
            _buildSectionCard(
              title: '1. Policy & User Identification',
              icon: Icons.badge_outlined,
              children: [
                TextFormField(
                  controller: _policyIdController,
                  decoration: const InputDecoration(
                    labelText: 'Policy number *',
                    hintText: 'e.g. POL-MOT-88231',
                    prefixIcon: Icon(Icons.shield_outlined),
                  ),
                  validator: (val) {
                    if (val == null ||
                        val.trim().isEmpty ||
                        val.trim() == 'POL-MOT-') {
                      return 'Valid policy number required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _claimantNameController,
                  decoration: const InputDecoration(
                    labelText: 'Claimant Full Name *',
                    hintText: 'e.g. Alex Fernando',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Please enter claimant name';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone Number *',
                    hintText: 'e.g. +94 77 123 4567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Contact number required';
                    return null;
                  },
                ),
              ],
            ),

            // Section 2: Vehicle Details
            _buildSectionCard(
              title: '2. Vehicle Specifications',
              icon: Icons.directions_car_outlined,
              children: [
                TextFormField(
                  controller: _vehicleRegController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Registration Number *',
                    hintText: 'e.g. WP-CAB-1234',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vehicle registration number required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _vehicleMakeController,
                        decoration: const InputDecoration(
                          labelText: 'Make *',
                          hintText: 'e.g. Toyota',
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _vehicleModelController,
                        decoration: const InputDecoration(
                          labelText: 'Model *',
                          hintText: 'e.g. Corolla',
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _vehicleYear,
                        decoration: const InputDecoration(labelText: 'Year'),
                        items: List.generate(25, (index) => 2026 - index)
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text(y.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _vehicleYear = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _vehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type',
                        ),
                        items: _vehicleTypes
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _vehicleType = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Section 3: Incident Details
            _buildSectionCard(
              title: '3. Incident & Accident Details',
              icon: Icons.warning_amber_rounded,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectIncidentDate,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text('Date: $dateDisplay'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectIncidentTime,
                        icon: const Icon(Icons.access_time_outlined),
                        label: Text('Time: $timeDisplay'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _incidentLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Incident Location / City *',
                    hintText: 'e.g. Galle Road, Colombo 03',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Accident location required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _incidentType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Incident Type',
                        ),
                        items: _incidentTypes
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _incidentType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _damageSeverity,
                        decoration: const InputDecoration(
                          labelText: 'Damage Severity',
                        ),
                        items: _severities
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _damageSeverity = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Is the vehicle drivable?'),
                  subtitle: Text(
                    _isVehicleDrivable
                        ? 'Vehicle is operational'
                        : 'Vehicle requires towing assistance',
                  ),
                  value: _isVehicleDrivable,
                  onChanged: (val) => setState(() => _isVehicleDrivable = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Was a police report filed?'),
                  subtitle: Text(
                    _policeReportFiled
                        ? 'Police entry recorded'
                        : 'No police report filed',
                  ),
                  value: _policeReportFiled,
                  onChanged: (val) => setState(() => _policeReportFiled = val),
                ),
                if (_policeReportFiled) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _policeReportNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Police Report Reference Number *',
                      hintText: 'e.g. PR-COL-2026-1102',
                      prefixIcon: Icon(Icons.local_police_outlined),
                    ),
                    validator: (val) {
                      if (_policeReportFiled &&
                          (val == null || val.trim().isEmpty)) {
                        return 'Please provide police report reference';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),

            // Section 4: Driver & Third Party
            _buildSectionCard(
              title: '4. Driver & Third Party Details',
              icon: Icons.people_outline_rounded,
              children: [
                TextFormField(
                  controller: _driverNameController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Name at Time of Incident',
                    hintText: 'Leave empty if same as claimant',
                    prefixIcon: Icon(Icons.person_pin_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _driverLicenseController,
                        decoration: const InputDecoration(
                          labelText: 'Driving License No *',
                          hintText: 'e.g. B1234567',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty)
                            return 'License number required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _relationshipToInsured,
                        decoration: const InputDecoration(
                          labelText: 'Relationship to Insured',
                        ),
                        items: _relationships
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _relationshipToInsured = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Was a third party involved?'),
                  subtitle: const Text(
                    'Another vehicle, pedestrian, or third-party property',
                  ),
                  value: _thirdPartyInvolved,
                  onChanged: (val) => setState(() => _thirdPartyInvolved = val),
                ),
                if (_thirdPartyInvolved) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _thirdPartyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Third Party Full Name',
                      hintText: 'e.g. Kasun Fernando',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _thirdPartyVehicleController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Third Party Vehicle No',
                            hintText: 'e.g. WP-CAB-9900',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _thirdPartyContactController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Third Party Phone',
                            hintText: 'e.g. +94 71 234 5678',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _thirdPartyInsuranceController,
                    decoration: const InputDecoration(
                      labelText: 'Third Party Insurance Company',
                      hintText: 'e.g. Sri Lanka Insurance / Ceylinco',
                    ),
                  ),
                ],
              ],
            ),

            // Section 5: Financial Estimate & Loss Description
            _buildSectionCard(
              title: '5. Repair Amount & Description',
              icon: Icons.attach_money_rounded,
              children: [
                TextFormField(
                  controller: _claimAmountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Claim Amount (\$) [Shared Field] *',
                    hintText: 'e.g. 1500.00',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Please enter claim amount';
                    final n = double.tryParse(val.trim());
                    if (n == null || n <= 0)
                      return 'Please enter a valid positive number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description (Shared Field) *',
                    hintText: 'Provide a detailed account of how the accident occurred and the damage sustained...',
                    alignLabelWithHint: true,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 10) {
                      return 'Please provide at least 10 characters description';
                    }
                    return null;
                  },
                ),
              ],
            ),

            // Section 6: Upload Accident Photos & Supporting Documents
            _buildSectionCard(
              title: '6. Accident Photos & Supporting Documents',
              icon: Icons.add_a_photo_outlined,
              children: [
                const Text(
                  'Accident Photos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickAccidentPhotos,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Choose Accident Photos'),
                ),
                if (_selectedAccidentPhotos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No photos selected. Add at least one accident photo.',
                    ),
                  )
                else
                  ..._selectedAccidentPhotos.asMap().entries.map(
                    (entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.image_outlined,
                        color: InsureCareTheme.navy,
                      ),
                      title: Text(
                        entry.value.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: const Text('Selected for upload'),
                      trailing: IconButton(
                        tooltip: 'Remove photo',
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _isSubmitting
                            ? null
                            : () => setState(
                                () =>
                                    _selectedAccidentPhotos.removeAt(entry.key),
                              ),
                      ),
                    ),
                  ),

                const Divider(height: 28),

                const Text(
                  'Supporting Documents',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickSupportingDocuments,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Choose Supporting Documents'),
                ),
                if (_selectedSupportingFiles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Optional: Add a police report, driving licence, or repair quotation.',
                    ),
                  )
                else
                  ..._selectedSupportingFiles.asMap().entries.map(
                    (entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.description_outlined,
                        color: InsureCareTheme.navy,
                      ),
                      title: Text(
                        entry.value.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: const Text('Selected for upload'),
                      trailing: IconButton(
                        tooltip: 'Remove document',
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _isSubmitting
                            ? null
                            : () => setState(
                                () => _selectedSupportingFiles.removeAt(
                                  entry.key,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),

            // Declaration Checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _agreedToTerms,
              onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
              title: const Text(
                'I declare that the information provided above and attached photos are true and correct.',
                style: TextStyle(fontSize: 12.5),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting
                      ? 'Submitting your claim...'
                      : 'Submit Motor Claim',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: InsureCareTheme.navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ClaimFormTip extends StatelessWidget {
  const _ClaimFormTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: InsureCareTheme.paleBlue,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: InsureCareTheme.iconBlue,
            size: 21,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Here when you need us.',
                  style: TextStyle(
                    color: InsureCareTheme.navy,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Keep your policy information, accident details and supporting documents ready.',
                  style: TextStyle(
                    color: InsureCareTheme.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
