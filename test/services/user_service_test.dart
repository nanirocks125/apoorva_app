import 'package:apoorva_app/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        // 1. Setup: Create a root user and an organization
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

        // Seed the root user
        await fakeDb.collection('users').doc(userId).set(user.toJson());

        // 2. Execute Mapping
        await userService.mapUserToOrganization(
          fullUser: user,
          fullOrg: org,
          orgRole: 'manager',
        );

        // 3. Verify Path A: Organization's staff sub-collection
        final orgStaffDoc = await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('users')
            .doc(userId)
            .get();

        expect(orgStaffDoc.exists, isTrue);
        expect(orgStaffDoc.get('orgRole'), 'manager');

        // 4. Verify Path B: Root User's assignedOrgs array
        final userDoc = await fakeDb.collection('users').doc(userId).get();
        final List assignedOrgs = userDoc.get('assignedOrgs');

        expect(assignedOrgs.length, 1);
        expect(assignedOrgs.first['name'], 'Apoorva Mangalagiri');
      },
    );

    test('unmapUserFromOrganization should cleanup both locations', () async {
      const String userId = 'staff_01';
      const String orgId = 'guntur_branch';

      // 1. Setup: Seed mapped data
      await fakeDb.collection('users').doc(userId).set({
        'assignedOrgs': [
          {'orgId': orgId, 'name': 'Guntur'},
        ],
      });
      await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('users')
          .doc(userId)
          .set({'name': 'Staff'});

      // 2. Execute Unmapping
      await userService.unmapUserFromOrganization(userId: userId, orgId: orgId);

      // 3. Verify
      final userDoc = await fakeDb.collection('users').doc(userId).get();
      expect((userDoc.get('assignedOrgs') as List).isEmpty, isTrue);

      final orgStaffDoc = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('users')
          .doc(userId)
          .get();
      expect(orgStaffDoc.exists, isFalse);
    });
  });

  group('UserService - Data Fetching', () {
    test('getUserById should return correctly parsed AppUser', () async {
      const String uid = 'test_uid';
      await fakeDb.collection('users').doc(uid).set({
        'id': uid,
        'name': 'Apoorva Admin',
        'email': 'admin@apoorva.com',
        'role': 'superAdmin',
      });

      final result = await userService.getUserById(uid);

      expect(result, isNotNull);
      expect(result!.name, 'Apoorva Admin');
      expect(result.id, uid);
    });
  });
}
