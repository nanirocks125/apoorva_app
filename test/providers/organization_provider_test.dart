import 'package:apoorva_app/model/organization/organization_snapshot.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/services/organization_service.dart';

// --- Mocks ---
class MockOrganizationService extends Mock implements OrganizationService {}

class MockAppUser extends Mock implements AppUser {}

class MockOrganization extends Mock implements Organization {}

class MockOrganizationSnapshot extends Mock implements OrganizationSnapshot {}

void main() {
  late OrganizationProvider provider;
  late MockOrganizationService mockOrganizationService;

  setUp(() {
    mockOrganizationService = MockOrganizationService();
    provider = OrganizationProvider(
      organizationService: mockOrganizationService,
    );
  });

  group('OrganizationProvider - Initial State', () {
    test('starts with null organization and is not loading', () {
      expect(provider.currentOrganization, isNull);
      expect(provider.isLoading, isFalse);
    });
  });

  group('updateForUser()', () {
    test('clears organization when user is null', () async {
      // Setup initial state with a dummy organization
      final mockOrg = MockOrganization();
      when(() => mockOrg.id).thenReturn('org_1');
      when(
        () => mockOrganizationService.getOrganizationById('org_1'),
      ).thenAnswer((_) async => mockOrg);

      // Simulate an initial valid user login to set the state
      final mockUser = MockAppUser();
      final mockSnapshot = MockOrganizationSnapshot();
      when(() => mockSnapshot.orgId).thenReturn('org_1');
      when(() => mockUser.assignedOrgs).thenReturn([mockSnapshot]);

      await provider.updateForUser(mockUser);
      expect(provider.currentOrganization, isNotNull);

      // Act: Update with null user (e.g., logout)
      await provider.updateForUser(null);

      // Assert
      expect(provider.currentOrganization, isNull);
      expect(provider.isLoading, isFalse);
    });

    test(
      'clears organization when user has no assigned organizations',
      () async {
        final mockUser = MockAppUser();
        when(() => mockUser.assignedOrgs).thenReturn([]); // Empty array

        await provider.updateForUser(mockUser);

        expect(provider.currentOrganization, isNull);
      },
    );

    test('fetches and sets organization for valid user', () async {
      final mockUser = MockAppUser();
      final mockOrg = MockOrganization();
      final mockSnapshot = MockOrganizationSnapshot();

      // Setup the user snapshot to return 'org_123'
      when(() => mockSnapshot.orgId).thenReturn('org_123');
      when(() => mockUser.assignedOrgs).thenReturn([mockSnapshot]);

      when(() => mockOrg.id).thenReturn('org_123');
      when(
        () => mockOrganizationService.getOrganizationById('org_123'),
      ).thenAnswer((_) async => mockOrg);

      // Track listener calls
      int listenerCallCount = 0;
      provider.addListener(() => listenerCallCount++);

      await provider.updateForUser(mockUser);

      expect(provider.currentOrganization, equals(mockOrg));
      expect(provider.isLoading, isFalse);

      // Verify the service was called exactly once
      verify(
        () => mockOrganizationService.getOrganizationById('org_123'),
      ).called(1);

      // Listeners should be notified: 1 for microtask(loading=true), 1 for finally(loading=false)
      expect(listenerCallCount, greaterThanOrEqualTo(2));
    });

    test(
      'prevents redundant network calls if organization is already loaded',
      () async {
        final mockUser = MockAppUser();
        final mockOrg = MockOrganization();
        final mockSnapshot = MockOrganizationSnapshot();

        // Setup the user snapshot
        when(() => mockSnapshot.orgId).thenReturn('org_123');
        when(() => mockUser.assignedOrgs).thenReturn([mockSnapshot]);

        when(() => mockOrg.id).thenReturn('org_123');
        when(
          () => mockOrganizationService.getOrganizationById('org_123'),
        ).thenAnswer((_) async => mockOrg);

        // Call it the first time
        await provider.updateForUser(mockUser);

        // Clear interactions to reset verification count
        clearInteractions(mockOrganizationService);

        // Call it a second time with the SAME user data
        await provider.updateForUser(mockUser);

        // Verify the service was NOT called again
        verifyNever(() => mockOrganizationService.getOrganizationById(any()));
      },
    );

    test('handles exceptions from the service gracefully', () async {
      final mockUser = MockAppUser();
      final mockSnapshot = MockOrganizationSnapshot();

      // Setup the user snapshot with an error-causing ID
      when(() => mockSnapshot.orgId).thenReturn('org_error');
      when(() => mockUser.assignedOrgs).thenReturn([mockSnapshot]);

      when(
        () => mockOrganizationService.getOrganizationById('org_error'),
      ).thenThrow(Exception('Network Error'));

      await provider.updateForUser(mockUser);

      // Assert state handled the failure
      expect(provider.currentOrganization, isNull);
      expect(
        provider.isLoading,
        isFalse,
      ); // Should reset to false despite error
    });
  });

  group('switchOrganization()', () {
    test('fetches and switches to the new organization', () async {
      final mockOrg = MockOrganization();
      when(() => mockOrg.id).thenReturn('org_999');
      when(
        () => mockOrganizationService.getOrganizationById('org_999'),
      ).thenAnswer((_) async => mockOrg);

      await provider.switchOrganization('org_999');

      expect(provider.currentOrganization, equals(mockOrg));
      expect(provider.isLoading, isFalse);
      verify(
        () => mockOrganizationService.getOrganizationById('org_999'),
      ).called(1);
    });

    test('handles exceptions during manual switch gracefully', () async {
      // First, set up an existing state
      final initialOrg = MockOrganization();
      when(() => initialOrg.id).thenReturn('org_1');
      when(
        () => mockOrganizationService.getOrganizationById('org_1'),
      ).thenAnswer((_) async => initialOrg);

      await provider.switchOrganization('org_1');
      expect(provider.currentOrganization, equals(initialOrg));

      // Attempt to switch to an organization that throws an error
      when(
        () => mockOrganizationService.getOrganizationById('org_fail'),
      ).thenThrow(Exception('Not Found'));

      await provider.switchOrganization('org_fail');

      // The catch block suppresses the error, and currentOrganization shouldn't be nullified
      // (it simply fails to update, remaining as 'org_1' based on your implementation)
      expect(provider.currentOrganization, equals(initialOrg));
      expect(provider.isLoading, isFalse);
    });
  });
}
