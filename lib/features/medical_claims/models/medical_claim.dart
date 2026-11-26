import 'package:cloud_firestore/cloud_firestore.dart';

import 'medical_bill_document.dart';
import 'medical_claim_status.dart';

class MedicalClaim {
  MedicalClaim({
    required this.claimId,
    required this.userId,
    required this.policyId,
    this.claimType = defaultClaimType,
    required this.claimAmount,
    required this.description,
    this.status = MedicalClaimStatus.submitted,
    List<MedicalBillDocument> documents = const [],
    required this.createdAt,
    required this.patientName,
    required this.patientRelationship,
    required this.hospitalName,
    required this.treatmentType,
    this.admissionDate,
    this.dischargeDate,
    this.billNumber,
    this.billDate,
  }) : documents = List.unmodifiable(documents);

  static const String defaultClaimType = 'Medical';
  static const String _metadataPrefix = '[Medical Claim]';

  static const List<String> relationships = [
    'Self',
    'Spouse',
    'Child',
    'Parent',
  ];

  static const List<String> treatmentTypes = [
    'Inpatient',
    'Outpatient',
    'Lab & Diagnostics',
    'Pharmacy',
  ];

  // Exact 9 core Firestore `claims` collection fields
  final String claimId;
  final String userId;
  final String policyId;
  final String claimType;
  final double claimAmount;
  final String description;
  final MedicalClaimStatus status;
  final List<MedicalBillDocument> documents;
  final DateTime createdAt;

  // Medical domain fields encoded cleanly inside `description` for Firestore
  final String patientName;
  final String patientRelationship;
  final String hospitalName;
  final String treatmentType;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String? billNumber;
  final DateTime? billDate;

  /// Formats medical metadata + user description into a single human-readable
  /// `description` string so the Firestore `claims` document strictly keeps
  /// the 9 backend-approved keys without losing medical context.
  String toFirestoreDescription() {
    final segments = <String>[
      'Hospital: ${_sanitizeMetaValue(hospitalName)}',
      'Patient: ${_sanitizeMetaValue(patientName)} (${_sanitizeMetaValue(patientRelationship)})',
      'Treatment: ${_sanitizeMetaValue(treatmentType)}',
      if (admissionDate != null) 'Admission: ${_formatIsoDate(admissionDate!)}',
      if (dischargeDate != null) 'Discharge: ${_formatIsoDate(dischargeDate!)}',
      if (billNumber != null && billNumber!.trim().isNotEmpty)
        'BillNo: ${_sanitizeMetaValue(billNumber!)}',
      if (billDate != null) 'BillDate: ${_formatIsoDate(billDate!)}',
    ];
    final cleanNotes = description.trim();
    return '$_metadataPrefix ${segments.join(' | ')}\n$cleanNotes';
  }

  /// Emits strictly the 9 keys permitted by `firestore.rules` and
  /// `docs/backend/database_schema.md`.
  Map<String, dynamic> toMap() {
    return {
      'claimId': claimId,
      'userId': userId,
      'policyId': policyId,
      'claimType': claimType,
      'claimAmount': claimAmount,
      'description': toFirestoreDescription(),
      'status': status.value,
      'documents': documents.map((doc) => doc.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MedicalClaim.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final rawDocuments = map['documents'];
    final parsedDocuments = <MedicalBillDocument>[];
    if (rawDocuments is List) {
      for (final item in rawDocuments) {
        if (item is Map<String, dynamic>) {
          parsedDocuments.add(MedicalBillDocument.fromMap(item));
        } else if (item is Map) {
          parsedDocuments.add(
            MedicalBillDocument.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final rawAmount = map['claimAmount'];
    final parsedAmount = switch (rawAmount) {
      num value => value.toDouble(),
      String value => double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0,
      _ => 0.0,
    };

    final mapClaimId = (map['claimId'] as String?)?.trim();
    final resolvedClaimId =
        (mapClaimId != null && mapClaimId.isNotEmpty)
            ? mapClaimId
            : (documentId ?? '');

    final rawDescription = (map['description'] as String?) ?? '';
    final decoded = _decodeDescription(rawDescription);

    return MedicalClaim(
      claimId: resolvedClaimId,
      userId: (map['userId'] as String?) ?? '',
      policyId: (map['policyId'] as String?) ?? '',
      claimType: (map['claimType'] as String?) ?? defaultClaimType,
      claimAmount: parsedAmount,
      description: decoded.notes,
      status: MedicalClaimStatus.fromValue(map['status'] as String?),
      documents: parsedDocuments,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      patientName:
          (map['patientName'] as String?) ??
          decoded.patientName ??
          'Policyholder',
      patientRelationship:
          (map['patientRelationship'] as String?) ??
          decoded.patientRelationship ??
          relationships.first,
      hospitalName:
          (map['hospitalName'] as String?) ??
          decoded.hospitalName ??
          'Medical Care',
      treatmentType:
          (map['treatmentType'] as String?) ??
          decoded.treatmentType ??
          treatmentTypes[1],
      admissionDate:
          _parseDateTime(map['admissionDate']) ?? decoded.admissionDate,
      dischargeDate:
          _parseDateTime(map['dischargeDate']) ?? decoded.dischargeDate,
      billNumber: (map['billNumber'] as String?) ?? decoded.billNumber,
      billDate: _parseDateTime(map['billDate']) ?? decoded.billDate,
    );
  }

  MedicalClaim copyWith({
    String? claimId,
    String? userId,
    String? policyId,
    String? claimType,
    double? claimAmount,
    String? description,
    MedicalClaimStatus? status,
    List<MedicalBillDocument>? documents,
    DateTime? createdAt,
    String? patientName,
    String? patientRelationship,
    String? hospitalName,
    String? treatmentType,
    DateTime? admissionDate,
    DateTime? dischargeDate,
    String? billNumber,
    DateTime? billDate,
  }) {
    return MedicalClaim(
      claimId: claimId ?? this.claimId,
      userId: userId ?? this.userId,
      policyId: policyId ?? this.policyId,
      claimType: claimType ?? this.claimType,
      claimAmount: claimAmount ?? this.claimAmount,
      description: description ?? this.description,
      status: status ?? this.status,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      patientName: patientName ?? this.patientName,
      patientRelationship: patientRelationship ?? this.patientRelationship,
      hospitalName: hospitalName ?? this.hospitalName,
      treatmentType: treatmentType ?? this.treatmentType,
      admissionDate: admissionDate ?? this.admissionDate,
      dischargeDate: dischargeDate ?? this.dischargeDate,
      billNumber: billNumber ?? this.billNumber,
      billDate: billDate ?? this.billDate,
    );
  }

  static String _sanitizeMetaValue(String input) =>
      input.replaceAll('|', '/').replaceAll('\n', ' ').trim();

  static String _formatIsoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static _DecodedMedicalMeta _decodeDescription(String raw) {
    if (!raw.startsWith(_metadataPrefix)) {
      return _DecodedMedicalMeta(notes: raw.trim());
    }

    final newlineIndex = raw.indexOf('\n');
    final headerLine = newlineIndex >= 0
        ? raw.substring(_metadataPrefix.length, newlineIndex).trim()
        : raw.substring(_metadataPrefix.length).trim();
    final notes = newlineIndex >= 0 ? raw.substring(newlineIndex + 1).trim() : '';

    String? hospitalName;
    String? patientName;
    String? patientRelationship;
    String? treatmentType;
    DateTime? admissionDate;
    DateTime? dischargeDate;
    String? billNumber;
    DateTime? billDate;

    for (final part in headerLine.split('|')) {
      final trimmed = part.trim();
      final colonIdx = trimmed.indexOf(':');
      if (colonIdx <= 0) continue;

      final key = trimmed.substring(0, colonIdx).trim();
      final val = trimmed.substring(colonIdx + 1).trim();
      if (val.isEmpty) continue;

      switch (key) {
        case 'Hospital':
          hospitalName = val;
        case 'Patient':
          final relMatch = RegExp(r'^(.*)\(([^()]+)\)$').firstMatch(val);
          if (relMatch != null) {
            patientName = relMatch.group(1)?.trim();
            patientRelationship = relMatch.group(2)?.trim();
          } else {
            patientName = val;
          }
        case 'Treatment':
          treatmentType = val;
        case 'Admission':
          admissionDate = DateTime.tryParse(val);
        case 'Discharge':
          dischargeDate = DateTime.tryParse(val);
        case 'BillNo':
          billNumber = val;
        case 'BillDate':
          billDate = DateTime.tryParse(val);
      }
    }

    return _DecodedMedicalMeta(
      notes: notes,
      hospitalName: hospitalName,
      patientName: patientName,
      patientRelationship: patientRelationship,
      treatmentType: treatmentType,
      admissionDate: admissionDate,
      dischargeDate: dischargeDate,
      billNumber: billNumber,
      billDate: billDate,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}

class _DecodedMedicalMeta {
  const _DecodedMedicalMeta({
    required this.notes,
    this.hospitalName,
    this.patientName,
    this.patientRelationship,
    this.treatmentType,
    this.admissionDate,
    this.dischargeDate,
    this.billNumber,
    this.billDate,
  });

  final String notes;
  final String? hospitalName;
  final String? patientName;
  final String? patientRelationship;
  final String? treatmentType;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String? billNumber;
  final DateTime? billDate;
}
