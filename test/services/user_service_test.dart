import 'package:apoorva_app/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/model/organization/organization.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late UserService userService;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    userService = UserService(db: fakeDb);
  });

  group('UserService - Mapping & Batch Logic', () {
    test(
      'mapUserToOrganization should update both User and Org collections',
      () async {
        const String userId = 'user_leo_123';
        const String orgId = 'mangalagiri_branch';

        final user = AppUser(
          id: userId,
          name: 'Manikanta',
          email: 'mani@apoorva.com',
          createdAt: DateTime.now(),
        );
        final org = Organization(
          id: orgId,
          name: 'Apoorva Mangalagiri',
          createdAt: DateTime.now(),
        );

        await fakeDb.collection('users').doc(userId).set(user.toJson());

        await userService.mapUserToOrganization(
          fullUser: user,
          fullOrg: org,
          orgRole: 'manager',
        );

        final orgStaffDoc = await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('users')
            .doc(userId)
            .get();

        expect(orgStaffDoc.exists, isTrue);
        expect(orgStaffDoc.get('orgRole'), 'manager');

        final userDoc = await fakeDb.collection('users').doc(userId).get();
        final List assignedOrgs = userDoc.get('assignedOrgs');

        expect(assignedOrgs.length, 1);
        expect(assignedOrgs.first['name'], 'Apoorva Mangalagiri');
      },
    );

    test('unmapUserFromOrganization should cleanup both locations', () async {
      const String userId = 'staff_01';
      const String orgId = 'guntur_branch';

      await fakeDb.collection('users').doc(userId).set({
        'assignedOrgs': [
          {'orgId': orgId, 'name': 'Guntur'},
          {'orgId': 'other_branch', 'name': 'Other'},
        ],
      });
      await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('users')
          .doc(userId)
          .set({'name': 'Staff'});

      await userService.unmapUserFromOrganization(userId: userId, orgId: orgId);

      final userDoc = await fakeDb.collection('users').doc(userId).get();
      final assignedOrgs = userDoc.get('assignedOrgs') as List;

      // Should remove Guntur but keep Other
      expect(assignedOrgs.length, 1);
      expect(assignedOrgs.first['orgId'], 'other_branch');

      final orgStaffDoc = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('users')
          .doc(userId)
          .get();
      expect(orgStaffDoc.exists, isFalse);
    });

    test(
      'unmapUserFromOrganization should return early if user does not exist',
      () async {
        // Expect no errors thrown when trying to unmap a non-existent user
        await expectLater(
          userService.unmapUserFromOrganization(
            userId: 'ghost_user',
            orgId: 'org1',
          ),
          completes,
        );
      },
    );
  });

  group('UserService - Basic CRUD Operations', () {
    test('saveUser should add user to organization sub-collection', () async {
      const orgId = 'org_1';
      final user = AppUser(
        id: 'u1',
        name: 'Shop Staff',
        email: 'staff@shop.com',
        createdAt: DateTime.now(),
      );

      await userService.saveUser(orgId, user);

      final doc = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('users')
          .doc(user.id)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['name'], 'Shop Staff');
    });

    test(
      'deleteUser should remove user from organization sub-collection',
      () async {
        const orgId = 'org_1';
        const userId = 'u1';

        await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('users')
            .doc(userId)
            .set({'name': 'To Be Deleted'});

        await userService.deleteUser(orgId, userId);

        final doc = await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('users')
            .doc(userId)
            .get();

        expect(doc.exists, isFalse);
      },
    );

    test(
      'saveGlobalUser should add user directly to root users collection',
      () async {
        final user = AppUser(
          id: 'global_u1',
          name: 'Global Admin',
          email: 'admin@global.com',
          createdAt: DateTime.now(),
        );

        await userService.saveGlobalUser(user);

        final doc = await fakeDb.collection('users').doc(user.id).get();

        expect(doc.exists, isTrue);
        expect(doc.data()!['email'], 'admin@global.com');
      },
    );
  });

  group('UserService - Streams & Fetching', () {
    test('getUserById should return correctly parsed AppUser', () async {
      const String uid = 'test_uid';
      await fakeDb.collection('users').doc(uid).set({
        'id': uid,
        'name': 'Apoorva Admin',
        'email': 'admin@apoorva.com',
        'role': 'super_admin',
      });

      final result = await userService.getUserById(uid);

      expect(result, isNotNull);
      expect(result!.name, 'Apoorva Admin');
      expect(result.id, uid);
    });

    test('getUserById should return null when user does not exist', () async {
      final result = await userService.getUserById('non_existent_uid');
      expect(result, isNull);
    });

    test('getAllUsersGlobal streams all users from root collection', () async {
      await fakeDb.collection('users').doc('u1').set({
        'id': 'u1',
        'name': 'User 1',
        'email': 'user1@apoorva.com', // Added missing required field
        'role': 'standard', // Added missing required field
      });
      await fakeDb.collection('users').doc('u2').set({
        'id': 'u2',
        'name': 'User 2',
        'email': 'user2@apoorva.com', // Added missing required field
        'role': 'standard', // Added missing required field
      });

      final stream = userService.getAllUsersGlobal();
      final users = await stream.first;

      expect(users.length, 2);
      expect(users.any((u) => u.id == 'u1'), isTrue);
    });

    test('getStaffForOrg streams AppUsers from org sub-collection', () async {
      const orgId = 'org_123';
      await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('users')
          .doc('u1')
          .set({
            'id': 'u1',
            'name': 'Org User',
            'email': 'user1@apoorva.com',
            'role': 'standard',
          });

      final stream = userService.getStaffForOrg(orgId);
      final users = await stream.first;

      expect(users.length, 1);
      expect(users.first.name, 'Org User');
    });

    test(
      'getUserShops streams OrganizationSnapshots from user sub-collection',
      () async {
        const userId = 'user_123';
        await fakeDb
            .collection('users')
            .doc(userId)
            .collection('organizations')
            .doc('org1')
            .set({'orgId': 'org1', 'name': 'My Shop'});

        final stream = userService.getUserShops(userId);
        final shops = await stream.first;

        expect(shops.length, 1);
        expect(shops.first.name, 'My Shop');
        expect(shops.first.orgId, 'org1');
      },
    );

    test(
      'getOrganizationUsers streams AppUserSnapshots from org sub-collection',
      () async {
        const orgId = 'org_123';
        await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('users')
            .doc('u1')
            .set({
              'uid': 'u1',
              'name': 'Snap User',
              'email': 'user1@apoorva.com',
              'role': 'standard', // Added missing required field
            });

        final stream = userService.getOrganizationUsers(orgId);
        final snapshots = await stream.first;

        expect(snapshots.length, 1);
        expect(snapshots.first.name, 'Snap User');
        expect(snapshots.first.orgRole, 'staff');
      },
    );
  });
}
