import 'package:apoorva_app/services/organization_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/category/category.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late OrganizationService orgService;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    orgService = OrganizationService(db: fakeDb);
  });

  group('Organization Management Tests', () {
    test('getOrganizations should return stream with injected IDs', () async {
      // Setup: Add raw data to Firestore
      await fakeDb.collection('organizations').doc('mangalagiri_01').set({
        'name': 'Apoorva Mangalagiri',
        'status': 'Active',
        'createdAt': Timestamp.now(),
      });

      final stream = orgService.getOrganizations();
      final results = await stream.first;

      expect(results.length, 1);
      expect(results.first.name, 'Apoorva Mangalagiri');
      // Verify the manual ID injection logic worked
      expect(results.first.id, 'mangalagiri_01');
    });

    test(
      'createOrganization should generate a new doc and assign ID',
      () async {
        final newOrg = Organization(
          name: 'Guntur Branch',
          status: 'Active',
          createdAt: DateTime.now(),
        );

        await orgService.createOrganization(newOrg);

        final snapshot = await fakeDb.collection('organizations').get();
        expect(snapshot.docs.length, 1);
        expect(snapshot.docs.first.get('name'), 'Guntur Branch');
        expect(snapshot.docs.first.id, isNotEmpty);
      },
    );

    test('toggleStatus should flip Active to Inactive', () async {
      const String id = 'branch_123';
      await fakeDb.collection('organizations').doc(id).set({
        'status': 'Active',
      });

      await orgService.toggleStatus(id, 'Active');

      final doc = await fakeDb.collection('organizations').doc(id).get();
      expect(doc.get('status'), 'Inactive');
    });

    test(
      'deleteOrganization should wipe main doc and sub-collections',
      () async {
        const String orgId = 'temp_org';
        final orgRef = fakeDb.collection('organizations').doc(orgId);

        // 1. Setup: Create main doc and a sub-collection doc
        await orgRef.set({'name': 'To Be Deleted'});
        await orgRef.collection('users').doc('user_1').set({'name': 'Staff'});

        // 2. Execute
        await orgService.deleteOrganization(orgId);

        // 3. Verify: Everything is gone
        final mainDoc = await orgRef.get();
        final subDoc = await orgRef.collection('users').doc('user_1').get();

        expect(mainDoc.exists, isFalse);
        expect(subDoc.exists, isFalse);
      },
    );
  });

  group('Inventory & Category Sub-collection Tests', () {
    test(
      'getLiveCategories should fetch from "inventory" sub-collection',
      () async {
        const String orgId = 'org_1';
        await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('inventory')
            .add({
              'id': 'cat_001', // ✅ Add this! The model needs an ID string
              'name': 'Gold Rings',
              'billMachineNumber': 5,
              'currentStock': 10,
              'isHotkey': true,
            });

        final stream = orgService.getLiveCategories(orgId);
        final results = await stream.first;

        expect(results.length, 1);
        expect(results.first.name, 'Gold Rings');
      },
    );

    test('saveCategory should handle both add and update', () async {
      const String orgId = 'org_1';
      final category = Category(
        id: '',
        name: 'New Category',
        billMachineNumber: 1,
        currentStock: 0,
        isHotkey: false,
      );

      // Test Add
      await orgService.saveCategory(orgId, category);
      var snapshot = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('inventory')
          .get();
      expect(snapshot.docs.length, 1);

      // Test Update
      final existingId = snapshot.docs.first.id;
      await orgService.saveCategory(orgId, category, catId: existingId);
      // Still 1 doc, just updated
      snapshot = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('inventory')
          .get();
      expect(snapshot.docs.length, 1);
    });
  });
}
