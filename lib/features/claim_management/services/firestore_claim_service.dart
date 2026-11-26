import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/claim.dart';
import '../models/claim_document.dart';
import 'claim_service.dart';

class FirestoreClaimService extends ClaimService {
  FirestoreClaimService._(this._collection, this._documentIds, super.claims);

  final CollectionReference<Map<String, dynamic>> _collection;
  final Map<String, String> _documentIds;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static Future<FirestoreClaimService> load(FirebaseFirestore firestore) async {
    final collection = firestore.collection('claims');
    final snapshot = await collection.get(
      const GetOptions(source: Source.server),
    );
    final claims = <Claim>[];
    final documentIds = <String, String>{};
    for (final document in snapshot.docs) {
      final claim = _decode(document.id, document.data());
      if (documentIds.containsKey(claim.claimId)) {
        throw const FormatException('Duplicate claim ID');
      }
      documentIds[claim.claimId] = document.id;
      claims.add(claim);
    }
    return FirestoreClaimService._(collection, documentIds, claims);
  }

  @override
  Future<bool> updateStatus(
    String claimId,
    ClaimStatus expected,
    ClaimStatus next,
  ) async {
    final documentId = _documentIds[claimId];
    if (documentId == null || !reviewOptions(expected).contains(next)) {
      return false;
    }

    final reference = _collection.doc(documentId);
    final (saved, latest) = await _collection.firestore.runTransaction((
      transaction,
    ) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      if (data == null) return (false, null);
      final claim = _decode(documentId, data);
      if (claim.claimId != claimId || claim.status != expected) {
        return (false, claim);
      }
      transaction.update(reference, {'status': next.value});
      return (true, claim.withStatus(next));
    });

    if (!_disposed) {
      replaceClaim(claimId, latest?.claimId == claimId ? latest : null);
    }
    return saved;
  }

  static Claim _decode(String documentId, Map<String, dynamic> data) => Claim(
    claimId: data['claimId'] as String? ?? documentId,
    userId: data['userId'] as String,
    policyId: data['policyId'] as String,
    claimType: data['claimType'] as String,
    claimAmount: data['claimAmount'] as num,
    description: data['description'] as String? ?? '',
    status: ClaimStatus.values.firstWhere(
      (status) => status.value == data['status'],
    ),
    createdAt: _date(data['createdAt']),
    documents: [
      for (final item in (data['documents'] as List? ?? const []))
        ClaimDocument(
          documentId: item['documentId'] as String,
          documentType: item['documentType'] as String,
          fileName: item['fileName'] as String,
          storagePath: item['storagePath'] as String? ?? '',
          uploadedAt: _date(item['uploadedAt']),
        ),
    ],
  );

  static DateTime _date(Object? value) => switch (value) {
    Timestamp timestamp => timestamp.toDate(),
    String text => DateTime.parse(text),
    _ => throw const FormatException('Invalid claim date'),
  };
}
