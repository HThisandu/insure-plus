import 'claim_document.dart';
import 'claim_status.dart';

/// Base Common Claim Model representing shared insurance claim attributes in Insure-Plus.
///
/// Uses exactly the required shared claim fields:
/// - [claimId]: Unique identifier for the claim (e.g. 'CLM-MOT-2026-001')
/// - [userId]: User ID of the claimant (e.g. 'USR-78401')
/// - [policyId]: Policy identifier linked to the claim (e.g. 'POL-MOT-88231')
/// - [claimType]: Category of insurance claim (e.g. 'Motor Claim')
/// - [claimAmount]: Estimated or claimed repair amount
/// - [description]: Detailed incident and loss description
/// - [status]: Current lifecycle status (Submitted, UnderReview, MoreInfoRequired, Approved, Rejected)
/// - [documents]: List of [ClaimDocument] objects (documentId, documentType, fileName, fileUrl, uploadedAt)
/// - [createdAt]: Timestamp when the claim was submitted
class Claim {
  final String claimId;
  final String userId;
  final String policyId;
  final String claimType;
  final double claimAmount;
  final String description;
  final ClaimStatus status;
  final List<ClaimDocument> documents;
  final DateTime createdAt;

  Claim({
    required this.claimId,
    required this.userId,
    required this.policyId,
    this.claimType = 'Motor Claim',
    required this.claimAmount,
    required this.description,
    this.status = ClaimStatus.submitted,
    this.documents = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Backward-compatible aliases
  String get id => claimId;
  String get policyNumber => policyId;
  DateTime get submissionDate => createdAt;
  List<ClaimDocument> get attachedDocuments => documents;

  /// Formatted creation / submission date as YYYY-MM-DD
  String get formattedSubmissionDate {
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
  }

  /// Formatted claim amount as a currency string (e.g. $1,250.00)
  String get formattedAmount {
    return '\$${claimAmount.toStringAsFixed(2)}';
  }

  /// Converts the shared claim fields to a Map for Firestore persistence.
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
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Constructs a base Claim from a Map (e.g. from Firestore).
  factory Claim.fromMap(Map<String, dynamic> map) {
    return Claim(
      claimId: map['claimId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      policyId: map['policyId'] as String? ?? map['policyNumber'] as String? ?? '',
      claimType: map['claimType'] as String? ?? 'Motor Claim',
      claimAmount: (map['claimAmount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      status: ClaimStatus.fromString(map['status'] as String? ?? 'Submitted'),
      documents: (map['documents'] as List<dynamic>?)
              ?.map((item) {
                if (item is Map<String, dynamic>) {
                  return ClaimDocument.fromMap(item);
                } else if (item is Map) {
                  return ClaimDocument.fromMap(Map<String, dynamic>.from(item));
                } else if (item is String) {
                  return ClaimDocument(
                    documentId: 'DOC-${item.hashCode.abs()}',
                    documentType: item.toLowerCase().endsWith('.jpg') || item.toLowerCase().endsWith('.png')
                        ? 'AccidentPhoto'
                        : 'SupportingDocument',
                    fileName: item,
                    fileUrl: 'gs://insure-plus.appspot.com/claims/$item',
                  );
                }
                return ClaimDocument(
                  documentId: 'DOC-UNKNOWN',
                  documentType: 'General',
                  fileName: 'document',
                  fileUrl: '',
                );
              })
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
