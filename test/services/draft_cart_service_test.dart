import 'package:apoorva_app/services/draft_cart_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:apoorva_app/model/cart/draft_cart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late DraftCartService draftService;
  const String orgId = 'apoorva_mangalagiri';

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    draftService = DraftCartService(db: fakeDb);
  });

  group('DraftCartService Tests', () {
    test('getDraftsStream should emit correctly ordered drafts', () async {
      // 1. Setup: Seed two drafts with different timestamps
      final draftsColl = fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('drafts');

      await draftsColl.doc('id_old').set({
        'id': 'id_old',
        'customerName': 'Suresh',
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 30)),
        'customerPhone': '8121971462',
        'items': [],
        'total': 0,
      });

      await draftsColl.doc('id_new').set({
        'id': 'id_new',
        'customerName': 'Ramesh',
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 31)), // Newer
        'customerPhone': '8121971462',
        'items': [],
        'total': 0,
      });

      // 2. Execute
      final stream = draftService.getDraftsStream(orgId);
      final results = await stream.first;

      // 3. Verify ordering (descending: newer first)
      expect(results.length, 2);
      expect(results.first.customerName, 'Ramesh');
      expect(results.last.customerName, 'Suresh');
    });

    test('saveDraft should CREATE a new document if id is empty', () async {
      final newDraft = DraftCart(
        id: '', // Empty ID triggers auto-generated doc
        customerName: 'New Customer',
        createdAt: DateTime.now(),
        items: [],
        customerPhone: '',
        total: 0,
      );

      await draftService.saveDraft(orgId, newDraft);

      final snapshot = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('drafts')
          .get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.get('customerName'), 'New Customer');
    });

    test('saveDraft should UPDATE existing document using merge', () async {
      // 1. Setup: Existing draft
      const String draftId = 'draft_123';
      await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('drafts')
          .doc(draftId)
          .set({'id': draftId, 'customerName': 'Original Name', 'items': []});

      final updatedDraft = DraftCart(
        id: draftId,
        customerName: 'Updated Name',
        createdAt: DateTime.now(),
        items: [],
        customerPhone: '',
        total: 0,
      );

      // 2. Execute
      await draftService.saveDraft(orgId, updatedDraft);

      // 3. Verify
      final doc = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('drafts')
          .doc(draftId)
          .get();
      expect(doc.get('customerName'), 'Updated Name');
    });

    test('deleteDraft should remove the correct document', () async {
      // 1. Setup
      const String draftId = 'to_be_deleted';
      await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('drafts')
          .doc(draftId)
          .set({'id': draftId});

      // 2. Execute
      await draftService.deleteDraft(orgId, draftId);

      // 3. Verify
      final doc = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('drafts')
          .doc(draftId)
          .get();
      expect(doc.exists, isFalse);
    });
  });
}
