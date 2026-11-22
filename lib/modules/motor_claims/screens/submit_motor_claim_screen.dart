import 'package:flutter/material.dart';
import '../../../common/models/claim_document.dart';
import '../../../common/models/claim_status.dart';
import '../models/motor_claim.dart';
import '../services/motor_claim_service.dart';
import '../widgets/accident_photo_upload_widget.dart';
import '../widgets/document_picker_tile.dart';
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
  final _userIdController = TextEditingController(text: 'USR-78401');
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

  // Documents adhering to ClaimDocument schema
  final List<ClaimDocument> _accidentPhotoDocs = [
    ClaimDocument(
      documentId: 'PHOTO-001',
      documentType: 'AccidentPhoto',
      fileName: 'Front_Bumper_Damage.jpg',
      fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/Front_Bumper_Damage.jpg',
    ),
    ClaimDocument(
      documentId: 'PHOTO-002',
      documentType: 'AccidentPhoto',
      fileName: 'Accident_Scene_Wide.jpg',
      fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/Accident_Scene_Wide.jpg',
    ),
  ];

  final Map<String, bool> _supportingDocuments = {
    'Driver License Copy': true,
    'Police Accident Report': false,
    'Repair Garage Quotation': false,
    'Vehicle Revenue License': true,
  };

  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  final List<String> _vehicleTypes = ['Car', 'SUV', 'Motorcycle', 'Van', 'Commercial / Truck'];
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
  final List<String> _relationships = ['Self', 'Spouse', 'Son / Daughter', 'Employee', 'Authorized Driver'];

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

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form before submitting.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_accidentPhotoDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least 1 accident damage photo.'),
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

    setState(() {
      _isSubmitting = true;
    });

    final claimService = MotorClaimService();
    final newClaimId = claimService.generateNextClaimId();

    final timeString =
        '${_incidentTime.hour.toString().padLeft(2, '0')}:${_incidentTime.minute.toString().padLeft(2, '0')}';

    // Compile all documents conforming to ClaimDocument schema
    final List<ClaimDocument> allDocuments = List.from(_accidentPhotoDocs);

    _supportingDocuments.forEach((docTitle, isAttached) {
      if (isAttached) {
        final cleanName = docTitle.replaceAll(' ', '_');
        final docType = docTitle.contains('Police')
            ? 'PoliceReport'
            : (docTitle.contains('License') ? 'DrivingLicense' : 'SupportingDocument');

        allDocuments.add(
          ClaimDocument(
            documentId: 'DOC-SUPP-${cleanName.hashCode.abs()}',
            documentType: docType,
            fileName: '$cleanName.pdf',
            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/documents/$cleanName.pdf',
            uploadedAt: DateTime.now(),
          ),
        );
      }
    });

    final newClaim = MotorClaim(
      claimId: newClaimId,
      userId: _userIdController.text.trim(),
      policyId: _policyIdController.text.trim(),
      claimType: 'Motor Claim',
      claimAmount: double.tryParse(_claimAmountController.text.trim()) ?? 0.0,
      description: _descriptionController.text.trim(),
      status: ClaimStatus.submitted,
      documents: allDocuments,
      createdAt: DateTime.now(),
      claimantName: _claimantNameController.text.trim(),
      contactNumber: _contactNumberController.text.trim(),
      vehicleRegistrationNumber: _vehicleRegController.text.trim().toUpperCase(),
      vehicleMake: _vehicleMakeController.text.trim(),
      vehicleModel: _vehicleModelController.text.trim(),
      vehicleYear: _vehicleYear,
      vehicleType: _vehicleType,
      incidentDate: _incidentDate,
      incidentTime: timeString,
      incidentLocation: _incidentLocationController.text.trim(),
      incidentType: _incidentType,
      damageSeverity: _damageSeverity,
      isVehicleDrivable: _isVehicleDrivable,
      policeReportFiled: _policeReportFiled,
      policeReportNumber: _policeReportFiled ? _policeReportNumberController.text.trim() : null,
      driverName: _driverNameController.text.trim().isEmpty
          ? _claimantNameController.text.trim()
          : _driverNameController.text.trim(),
      driverLicenseNumber: _driverLicenseController.text.trim(),
      relationshipToInsured: _relationshipToInsured,
      thirdPartyInvolved: _thirdPartyInvolved,
      thirdPartyName: _thirdPartyInvolved ? _thirdPartyNameController.text.trim() : null,
      thirdPartyVehicleNumber:
          _thirdPartyInvolved ? _thirdPartyVehicleController.text.trim().toUpperCase() : null,
      thirdPartyContact: _thirdPartyInvolved ? _thirdPartyContactController.text.trim() : null,
      thirdPartyInsurance: _thirdPartyInvolved ? _thirdPartyInsuranceController.text.trim() : null,
      notes: 'Lodged via Insure-Plus Motor Claims Mobile App. Photos uploaded to Firebase.',
    );

    // Adds locally and syncs to Firebase Firestore
    claimService.addClaim(newClaim);

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    // Show Success Confirmation Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Claim Submitted!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your motor insurance claim and accident photos have been successfully submitted.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Claim Reference ID:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        newClaimId,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Attached Documents:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Text(
                        '${allDocuments.length} files',
                        style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Firebase Sync:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Text(
                        claimService.firebaseService.isFirebaseAvailable ? 'Cloud Synced' : 'Ready for Sync',
                        style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'An authorized motor surveyor will review your damage photos and contact you within 24 hours.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
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
                  builder: (_) => MotorClaimDetailsScreen(claimId: newClaimId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Claim Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.indigo.shade50,
                  child: Icon(icon, color: Colors.indigo, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
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
      appBar: AppBar(
        title: const Text('File Motor Claim'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Section 1: Policy & Claimant Details (Shared Schema)
            _buildSectionCard(
              title: '1. Policy & User Identification',
              icon: Icons.badge_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _userIdController,
                        decoration: const InputDecoration(
                          labelText: 'User ID (userId) *',
                          hintText: 'e.g. USR-78401',
                          prefixIcon: Icon(Icons.account_circle_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'User ID required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _policyIdController,
                        decoration: const InputDecoration(
                          labelText: 'Policy ID (policyId) *',
                          hintText: 'e.g. POL-MOT-88231',
                          prefixIcon: Icon(Icons.shield_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty || val.trim() == 'POL-MOT-') {
                            return 'Valid Policy ID required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
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
                    if (val == null || val.trim().isEmpty) return 'Please enter claimant name';
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
                    if (val == null || val.trim().isEmpty) return 'Contact number required';
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
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
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
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
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
                            .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
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
                        decoration: const InputDecoration(labelText: 'Vehicle Type'),
                        items: _vehicleTypes
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
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
                    if (val == null || val.trim().isEmpty) return 'Accident location required';
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
                        decoration: const InputDecoration(labelText: 'Incident Type'),
                        items: _incidentTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t, overflow: TextOverflow.ellipsis),
                                ))
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
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Is the vehicle drivable?'),
                  subtitle: Text(_isVehicleDrivable
                      ? 'Vehicle is operational'
                      : 'Vehicle requires towing assistance'),
                  value: _isVehicleDrivable,
                  onChanged: (val) => setState(() => _isVehicleDrivable = val),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Was a police report filed?'),
                  subtitle: Text(_policeReportFiled
                      ? 'Police entry recorded'
                      : 'No police report filed'),
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
                      if (_policeReportFiled && (val == null || val.trim().isEmpty)) {
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
                          if (val == null || val.trim().isEmpty) return 'License number required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _relationshipToInsured,
                        decoration: const InputDecoration(labelText: 'Relationship to Insured'),
                        items: _relationships
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _relationshipToInsured = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Was a third party involved?'),
                  subtitle: const Text('Another vehicle, pedestrian, or third-party property'),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Claim Amount (\$) [Shared Field] *',
                    hintText: 'e.g. 1500.00',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter claim amount';
                    final n = double.tryParse(val.trim());
                    if (n == null || n <= 0) return 'Please enter a valid positive number';
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
                // Accident Photos Uploader
                AccidentPhotoUploadWidget(
                  photos: _accidentPhotoDocs,
                  onAddPhoto: (photoName) {
                    setState(() {
                      if (!_accidentPhotoDocs.any((p) => p.fileName == photoName)) {
                        _accidentPhotoDocs.add(
                          ClaimDocument(
                            documentId: 'PHOTO-${DateTime.now().millisecondsSinceEpoch}',
                            documentType: 'AccidentPhoto',
                            fileName: photoName,
                            fileUrl: 'gs://insure-plus.appspot.com/motor_claims/photos/$photoName',
                            uploadedAt: DateTime.now(),
                          ),
                        );
                      }
                    });
                  },
                  onRemovePhoto: (photoDoc) {
                    setState(() {
                      _accidentPhotoDocs.remove(photoDoc);
                    });
                  },
                ),

                const Divider(height: 28),

                // Supporting Documents Checklist
                const Text(
                  'Supporting Documents (documents):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                const SizedBox(height: 8),
                ..._supportingDocuments.keys.map((docTitle) {
                  final isAttached = _supportingDocuments[docTitle] ?? false;
                  return DocumentPickerTile(
                    title: docTitle,
                    subtitle: isAttached ? 'Document file attached' : 'Tap to attach document',
                    isAttached: isAttached,
                    onToggle: () {
                      setState(() {
                        _supportingDocuments[docTitle] = !isAttached;
                      });
                    },
                  );
                }),
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Submitting to Firebase...' : 'Submit Motor Claim',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
