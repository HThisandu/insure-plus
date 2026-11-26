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
  static const String _metaTag = '[Medical Claim]';

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

  final String claimId;
  final String userId;
  final String policyId;
  final String claimType;
  final double claimAmount;
  final String description;
  final MedicalClaimStatus status;
  final List<MedicalBillDocument> documents;
  final DateTime createdAt;

  final String patientName;
  final String patientRelationship;
  final String hospitalName;
  final String treatmentType;
  final DateTime? admissionDate;
  final DateTime? dischargeDate;
  final String? billNumber;
  final DateTime? billDate;

  // Combines medical details into description so Firestore keeps the 9 core fields
  String toFirestoreDescription() {
    final parts = <String>[
      'Hospital: ${_cleanText(hospitalName)}',
      'Patient: ${_cleanText(patientName)} (${_cleanText(patientRelationship)})',
      'Treatment: ${_cleanText(treatmentType)}',
    ];
    if (admissionDate != null) {
      parts.add('Admission: ${_formatDate(admissionDate!)}');
    }
    if (dischargeDate != null) {
      parts.add('Discharge: ${_formatDate(dischargeDate!)}');
    }
    if (billNumber != null && billNumber!.trim().isNotEmpty) {
      parts.add('BillNo: ${_cleanText(billNumber!)}');
    }
    if (billDate != null) {
      parts.add('BillDate: ${_formatDate(billDate!)}');
    }
    return '$_metaTag ${parts.join(' | ')}\n${description.trim()}';
  }

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
    final parsedDocuments = <MedicalBillDocument>[];
    final rawDocs = map['documents'];
    if (rawDocs is List) {
      for (final item in rawDocs) {
        if (item is Map) {
          parsedDocuments.add(
            MedicalBillDocument.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    double parsedAmount = 0.0;
    final rawAmount = map['claimAmount'];
    if (rawAmount is num) {
      parsedAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      parsedAmount = double.tryParse(rawAmount.replaceAll(',', '')) ?? 0.0;
    }

    final idFromMap = (map['claimId'] as String?)?.trim() ?? '';
    final finalClaimId = idFromMap.isNotEmpty ? idFromMap : (documentId ?? '');

    final rawDesc = (map['description'] as String?) ?? '';
    String notes = rawDesc.trim();
    String? hospital;
    String? patient;
    String? relationship;
    String? treatment;
    DateTime? admission;
    DateTime? discharge;
    String? billNo;
    DateTime? billDt;

    if (rawDesc.startsWith(_metaTag)) {
      final lineBreak = rawDesc.indexOf('\n');
      final header = lineBreak >= 0
          ? rawDesc.substring(_metaTag.length, lineBreak).trim()
          : rawDesc.substring(_metaTag.length).trim();
      notes = lineBreak >= 0 ? rawDesc.substring(lineBreak + 1).trim() : '';

      for (final item in header.split('|')) {
        final colon = item.indexOf(':');
        if (colon <= 0) continue;
        final key = item.substring(0, colon).trim();
        final val = item.substring(colon + 1).trim();
        if (val.isEmpty) continue;

        if (key == 'Hospital') {
          hospital = val;
        } else if (key == 'Patient') {
          final open = val.lastIndexOf('(');
          final close = val.lastIndexOf(')');
          if (open > 0 && close > open) {
            patient = val.substring(0, open).trim();
            relationship = val.substring(open + 1, close).trim();
          } else {
            patient = val;
          }
        } else if (key == 'Treatment') {
          treatment = val;
        } else if (key == 'Admission') {
          admission = DateTime.tryParse(val);
        } else if (key == 'Discharge') {
          discharge = DateTime.tryParse(val);
        } else if (key == 'BillNo') {
          billNo = val;
        } else if (key == 'BillDate') {
          billDt = DateTime.tryParse(val);
        }
      }
    }

    return MedicalClaim(
      claimId: finalClaimId,
      userId: (map['userId'] as String?) ?? '',
      policyId: (map['policyId'] as String?) ?? '',
      claimType: (map['claimType'] as String?) ?? defaultClaimType,
      claimAmount: parsedAmount,
      description: notes,
      status: MedicalClaimStatus.fromValue(map['status'] as String?),
      documents: parsedDocuments,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      patientName: (map['patientName'] as String?) ?? patient ?? 'Policyholder',
      patientRelationship:
          (map['patientRelationship'] as String?) ??
          relationship ??
          relationships.first,
      hospitalName:
          (map['hospitalName'] as String?) ?? hospital ?? 'Medical Care',
      treatmentType:
          (map['treatmentType'] as String?) ?? treatment ?? treatmentTypes[1],
      admissionDate: _parseDate(map['admissionDate']) ?? admission,
      dischargeDate: _parseDate(map['dischargeDate']) ?? discharge,
      billNumber: (map['billNumber'] as String?) ?? billNo,
      billDate: _parseDate(map['billDate']) ?? billDt,
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

  static String _cleanText(String value) =>
      value.replaceAll('|', '/').replaceAll('\n', ' ').trim();

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
