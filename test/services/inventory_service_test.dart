import 'package:apoorva_app/services/inventory_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:apoorva_app/model/category/category.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late InventoryService inventoryService;
  const String orgId = 'apoorva_mangalagiri';

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    inventoryService = InventoryService(db: fakeDb);
  });

  group('InventoryService - Save & Duplicate Logic', () {
    test('saveCategory should CREATE a new category successfully', () async {
      final category = Category(
        id: '',
        name: 'Gold Bangles',
        billMachineNumber: 10,
        currentStock: 5,
        isHotkey: true,
      );

      await inventoryService.saveCategory(orgId, category);

      final snapshot = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('inventory')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.get('name'), 'Gold Bangles');
      expect(snapshot.docs.first.get('id'), isNotEmpty);
    });

    test(
      'should THROW Exception if billMachineNumber is already in use',
      () async {
        // 1. Setup: Add an existing category with number 15
        await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('inventory')
            .add({
              'id': 'existing_id',
              'name': 'Silver Rings',
              'billMachineNumber': 15,
              'currentStock': 0, // ✅ Add this
              'isHotkey': false, // ✅ Add this
            });

        // 2. Attempt: Add a NEW category with the same number 15
        final duplicateCategory = Category(
          id: '',
          name: 'New Rings',
          billMachineNumber: 15, // Duplicate!
          currentStock: 0,
          isHotkey: false,
        );

        // 3. Verify: Exception is thrown
        expect(
          () => inventoryService.saveCategory(orgId, duplicateCategory),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'should ALLOW update if billMachineNumber belongs to the SAME category',
      () async {
        const String catId = 'cat_123';
        await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('inventory')
            .doc(catId)
            .set({'id': catId, 'name': 'Earrings', 'billMachineNumber': 20});

        final updatedCategory = Category(
          id: catId,
          name: 'Earrings (Updated)',
          billMachineNumber: 20, // Same number, same ID
          currentStock: 10,
          isHotkey: true,
        );

        // Should NOT throw exception
        await inventoryService.saveCategory(orgId, updatedCategory);

        final doc = await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('inventory')
            .doc(catId)
            .get();

        expect(doc.get('name'), 'Earrings (Updated)');
      },
    );
  });

  group('InventoryService - Fetch & Delete', () {
    test(
      'getCategories should return list ordered by billMachineNumber',
      () async {
        final coll = fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('inventory');

        await coll.add({
          'name': 'Z',
          'billMachineNumber': 99,
          'id': 'id1',
          'currentStock': 0,
          'isHotkey': false,
        });
        await coll.add({
          'name': 'A',
          'billMachineNumber': 1,
          'id': 'id2',
          'currentStock': 0,
          'isHotkey': false,
        });

        final stream = inventoryService.getCategories(orgId);
        final results = await stream.first;

        expect(results.length, 2);
        expect(results.first.name, 'A'); // Number 1 should come first
        expect(results.last.name, 'Z');
      },
    );

    test('deleteCategory should remove the document', () async {
      const String docId = 'to_delete';
      await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('inventory')
          .doc(docId)
          .set({'id': docId});

      await inventoryService.deleteCategory(orgId, docId);

      final doc = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('inventory')
          .doc(docId)
          .get();

      expect(doc.exists, isFalse);
    });
  });
}
