import 'package:apoorva_app/model/cart/draft_cart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DraftCartService {
  final FirebaseFirestore _db;

  // Defaults to real Firestore, but accepts a fake one for tests
  DraftCartService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  // 1. Get Live Drafts Stream (Typed Models)
  Stream<List<DraftCart>> getDraftsStream(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('drafts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => DraftCart.fromFirestore(doc)).toList(),
        );
  }

  // 2. Save or Update Draft
  Future<void> saveDraft(String orgId, DraftCart draft) async {
    final ref = _db
        .collection('organizations')
        .doc(orgId)
        .collection('drafts')
        .doc(draft.id.isEmpty ? null : draft.id);

    await ref.set(draft.toJson(), SetOptions(merge: true));
  }

  // 3. Delete Draft
  Future<void> deleteDraft(String orgId, String draftId) async {
    await _db
        .collection('organizations')
        .doc(orgId)
        .collection('drafts')
        .doc(draftId)
        .delete();
  }
}
