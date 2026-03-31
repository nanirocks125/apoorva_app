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

  group('Organization Management - Core CRUD', () {
    test('getOrganizations should return stream with injected IDs', () async {
      await fakeDb.collection('organizations').doc('mangalagiri_01').set({
        'name': 'Apoorva Mangalagiri',
        'status': 'Active',
        'createdAt': Timestamp.now(),
      });

      final stream = orgService.getOrganizations();
      final results = await stream.first;

      expect(results.length, 1);
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
        expect(newOrg.id, isNotEmpty);
      },
    );

    test('updateOrganization should modify existing document fields', () async {
      const String id = 'org_123';
      final org = Organization(
        id: id,
        name: 'Old Name',
        status: 'Active',
        createdAt: DateTime.now(),
      );

      // Seed initial data
      await fakeDb.collection('organizations').doc(id).set(org.toJson());

      // Update name
      // Instead of mutating, create the updated version
      final updatedOrg = Organization(
        id: id,
        name: 'Updated Apoorva',
        status: 'Active',
        createdAt: org.createdAt,
      );
      await orgService.updateOrganization(updatedOrg);

      final doc = await fakeDb.collection('organizations').doc(id).get();
      expect(doc.get('name'), 'Updated Apoorva');
    });

    test(
      'toggleStatus should flip Active to Inactive and vice versa',
      () async {
        const String id = 'branch_test';
        await fakeDb.collection('organizations').doc(id).set({
          'status': 'Active',
        });

        // Active -> Inactive
        await orgService.toggleStatus(id, 'Active');
        var doc = await fakeDb.collection('organizations').doc(id).get();
        expect(doc.get('status'), 'Inactive');

        // Inactive -> Active
        await orgService.toggleStatus(id, 'Inactive');
        doc = await fakeDb.collection('organizations').doc(id).get();
        expect(doc.get('status'), 'Active');
      },
    );
  });

  group('Organization Management - Retrieval & Edge Cases', () {
    test(
      'getOrganizationById should return model for valid ID (with trim)',
      () async {
        const String id = 'mangalagiri_branch';
        await fakeDb.collection('organizations').doc(id).set({
          'name': 'Apoorva Mangalagiri',
          'status': 'Active',
          'createdAt': Timestamp.now(),
        });

        // Testing with a space to verify your .trim() logic
        final result = await orgService.getOrganizationById(
          ' mangalagiri_branch ',
        );
        expect(result, isNotNull);
        expect(result!.name, 'Apoorva Mangalagiri');
      },
    );

    test(
      'getOrganizationById should return null for non-existent doc',
      () async {
        final result = await orgService.getOrganizationById('ghost_id');
        expect(result, isNull);
      },
    );

    test('getOrganizationById should catch parsing errors', () async {
      const String id = 'bad_data_org';
      // Seed with data that will fail Organization.fromJson (e.g., missing fields or wrong types)
      await fakeDb.collection('organizations').doc(id).set({
        'name': 12345, // Should be a string
      });

      final result = await orgService.getOrganizationById(id);
      expect(result, isNull);
    });

    test('getMultipleOrgsByIds handles empty lists and valid IDs', () async {
      // 1. Test Empty early return
      final emptyResults = await orgService.getMultipleOrgsByIds([]);
      expect(emptyResults, isEmpty);

      // 2. Test valid IDs
      await fakeDb.collection('organizations').doc('id1').set({
        'name': 'Org 1',
        'status': 'Active',
        'createdAt': Timestamp.now(),
      });
      await fakeDb.collection('organizations').doc('id2').set({
        'name': 'Org 2',
        'status': 'Active',
        'createdAt': Timestamp.now(),
      });

      final results = await orgService.getMultipleOrgsByIds(['id1', 'id2']);
      expect(results.length, 2);
    });

    test('deleteOrganization should clean multiple sub-collections', () async {
      const String orgId = 'deletion_target';
      final orgRef = fakeDb.collection('organizations').doc(orgId);

      // Setup: Seed main doc and multiple sub-collections to trigger the loop
      await orgRef.set({'name': 'Main'});
      await orgRef.collection('users').doc('u1').set({'name': 'Staff'});
      await orgRef.collection('sales').doc('s1').set({'amount': 500});
      await orgRef.collection('audit_logs').doc('l1').set({'action': 'delete'});

      await orgService.deleteOrganization(orgId);

      expect((await orgRef.get()).exists, isFalse);
      expect(
        (await orgRef.collection('users').doc('u1').get()).exists,
        isFalse,
      );
      expect(
        (await orgRef.collection('audit_logs').doc('l1').get()).exists,
        isFalse,
      );
    });
  });

  group('Inventory & Category Tests', () {
    test('getLiveCategories should stream data from sub-collection', () async {
      const String orgId = 'org_inv';
      await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('inventory')
          .doc('cat_1')
          .set({
            'id': 'orgId',
            'name': 'Bangles',
            'billMachineNumber': 2,
            'currentStock': 20.0,
            'isHotkey': true,
          });

      final stream = orgService.getLiveCategories(orgId);
      final results = await stream.first;

      expect(results.length, 1);
      expect(results.first.name, 'Bangles');
    });

    test('saveCategory should handle add vs update correctly', () async {
      const String orgId = 'org_1';
      final category = Category(
        id: '',
        name: 'New Cat',
        billMachineNumber: 1,
        currentStock: 0,
        isHotkey: false,
      );

      // Test Add (catId is null)
      await orgService.saveCategory(orgId, category);
      var snap = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('inventory')
          .get();
      expect(snap.docs.length, 1);

      // Test Update (catId provided)
      final existingId = snap.docs.first.id;

      // 2. Create a NEW instance with the updated name
      final updatedCategory = Category(
        id: existingId,
        name: 'Updated Cat', // Set the new name here
        billMachineNumber: 1,
        currentStock: 0,
        isHotkey: false,
      );

      await orgService.saveCategory(orgId, updatedCategory, catId: existingId);

      final updatedDoc = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('inventory')
          .doc(existingId)
          .get();
      expect(updatedDoc.get('name'), 'Updated Cat');
    });
  });
}
