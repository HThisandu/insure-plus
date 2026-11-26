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

  // Core fields aligned with claim_management
  final String claimId;
  final String userId;
  final String policyId;
  final String claimType;
  final double claimAmount;
  final String description;
  final MedicalClaimStatus status;
  final List<MedicalBillDocument> documents;
  final DateTime createdAt;

  // Medical-specific fields
  final String patientName;
  final String patientRelationship;
  final String hospitalName;
  final String treatmentType;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String? billNumber;
  final DateTime? billDate;

  Map<String, dynamic> toMap() {
    return {
      'claimId': claimId,
      'userId': userId,
      'policyId': policyId,
      'claimType': claimType,
      'claimAmount': claimAmount,
      'description': description,
      'status': status.value,
      'documents': documents.map((doc) => doc.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'patientName': patientName,
      'patientRelationship': patientRelationship,
      'hospitalName': hospitalName,
      'treatmentType': treatmentType,
      'admissionDate':
          admissionDate != null ? Timestamp.fromDate(admissionDate!) : null,
      'dischargeDate':
          dischargeDate != null ? Timestamp.fromDate(dischargeDate!) : null,
      'billNumber': billNumber,
      'billDate': billDate != null ? Timestamp.fromDate(billDate!) : null,
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

    return MedicalClaim(
      claimId: resolvedClaimId,
      userId: (map['userId'] as String?) ?? '',
      policyId: (map['policyId'] as String?) ?? '',
      claimType: (map['claimType'] as String?) ?? defaultClaimType,
      claimAmount: parsedAmount,
      description: (map['description'] as String?) ?? '',
      status: MedicalClaimStatus.fromValue(map['status'] as String?),
      documents: parsedDocuments,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      patientName: (map['patientName'] as String?) ?? '',
      patientRelationship:
          (map['patientRelationship'] as String?) ?? relationships.first,
      hospitalName: (map['hospitalName'] as String?) ?? '',
      treatmentType:
          (map['treatmentType'] as String?) ?? treatmentTypes.first,
      admissionDate: _parseDateTime(map['admissionDate']),
      dischargeDate: _parseDateTime(map['dischargeDate']),
      billNumber: map['billNumber'] as String?,
      billDate: _parseDateTime(map['billDate']),
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

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
