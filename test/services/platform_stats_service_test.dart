import 'package:apoorva_app/services/platform_stats_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late FakeFirebaseFirestore fakeDb;
  late PlatformStatsService statsService;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    statsService = PlatformStatsService(db: fakeDb);
  });

  group('PlatformStatsService - Aggregate Counting Tests', () {
    test('should return accurate counts for Orgs and Users', () async {
      // 1. Setup: Seed Active Orgs
      await fakeDb.collection('organizations').add({
        'name': 'Org 1',
        'status': 'Active',
      });
      await fakeDb.collection('organizations').add({
        'name': 'Org 2',
        'status': 'Active',
      });

      // 2. Setup: Seed a Pending Request
      await fakeDb.collection('organizations').add({
        'name': 'New Branch Request',
        'status': 'Pending',
      });

      // 3. Setup: Seed Global Users
      await fakeDb.collection('users').add({
        'name': 'Manikanta',
        'role': 'super_admin',
      });
      await fakeDb.collection('users').add({
        'name': 'Staff 1',
        'role': 'staff',
      });

      // 4. Execute
      final stats = await statsService.getLivePlatformStats();

      // 5. Verify: counts should match seeded data
      expect(stats.activeOrgs, 2);
      expect(stats.newRequests, 1);
      expect(stats.globalUsers, 2);
      expect(stats.systemHealth, 'Optimal');
    });

    test('should return 0 counts when database is empty', () async {
      final stats = await statsService.getLivePlatformStats();

      expect(stats.activeOrgs, 0);
      expect(stats.globalUsers, 0);
      expect(stats.systemHealth, 'Optimal');
    });

    // Note: To test the 'Degraded' status, you would typically
    // mock a throw on the _db.collection() call using 'mocktail'.
  });

  group('PlatformStatsService - Error Handling Tests', () {
    late MockFirestore mockDb;
    late PlatformStatsService errorStatsService;

    setUp(() {
      mockDb = MockFirestore();
      errorStatsService = PlatformStatsService(db: mockDb);
    });

    test(
      'should return "Degraded" status when FirebaseException occurs',
      () async {
        // 1. Arrange: Firestore 'collection' కాల్ చేస్తే FirebaseException వచ్చేలా సెటప్ చేయడం
        when(() => mockDb.collection(any())).thenThrow(
          FirebaseException(plugin: 'firestore', code: 'permission-denied'),
        );

        // 2. Act
        final stats = await errorStatsService.getLivePlatformStats();

        // 3. Assert
        expect(stats.activeOrgs, 0);
        expect(stats.systemHealth, contains('Degraded: permission-denied'));
      },
    );

    test(
      'should return "Error" status when a generic Exception occurs',
      () async {
        // 1. Arrange: ఏదైనా అన్-హ్యాండిల్డ్ ఎర్రర్ వస్తే
        when(
          () => mockDb.collection(any()),
        ).thenThrow(Exception('Unknown Crash'));

        // 2. Act
        final stats = await errorStatsService.getLivePlatformStats();

        // 3. Assert
        expect(stats.activeOrgs, 0);
        expect(stats.systemHealth, 'Error');
      },
    );
  });
}
