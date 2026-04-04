import 'package:apoorva_app/enum/app_user_role.dart';
import 'package:apoorva_app/model/organization/organization_snapshot.dart';
import 'package:apoorva_app/screens/auth/login_screen.dart';
import 'package:apoorva_app/screens/dashboard/organization_dashboard_screen.dart';
import 'package:apoorva_app/screens/dashboard/super_admin_dashboard.dart';
import 'package:apoorva_app/screens/organization/organization_selection_screen.dart';
import 'package:apoorva_app/services/platform_stats_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:apoorva_app/screens/home_screen.dart'; // Adjust path
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:apoorva_app/services/auth_service.dart';

// Mocks
class MockOrgService extends Mock implements OrganizationService {}

class MockAuthService extends Mock implements AuthService {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockPlatformStatsService extends Mock implements PlatformStatsService {}

void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setupFirebaseCoreMocks();
}

void main() {
  late MockOrgService mockOrgService;
  late AppUser superAdmin;
  late AppUser unassignedUser;
  late AppUser multiOrgUser;
  late AppUser singleOrgUser;

  setupFirebaseMocks();

  setUpAll(() async {
    // Register fallback for navigation testing if needed
    registerFallbackValue(MaterialPageRoute(builder: (_) => Container()));

    await Firebase.initializeApp();
  });

  setUp(() {
    mockOrgService = MockOrgService();

    superAdmin = AppUser(
      name: 'Admin',
      role: AppUserRole.superAdmin,
      assignedOrgs: [],
      email: '',
      createdAt: DateTime(2023, 1, 1),
    );
    unassignedUser = AppUser(
      name: 'User 1',
      role: AppUserRole.standard,
      assignedOrgs: [],
      email: '',
      createdAt: DateTime(2023, 1, 1),
    );

    final org1 = Organization(
      id: '1',
      name: 'Shop 1',
      createdAt: DateTime(2023, 1, 1),
    );
    final org2 = Organization(
      id: '2',
      name: 'Shop 2',
      createdAt: DateTime(2023, 1, 1),
    );

    multiOrgUser = AppUser(
      name: 'User 2',
      role: AppUserRole.standard,
      assignedOrgs: [
        OrganizationSnapshot(orgId: org1.id, name: org1.name),
        OrganizationSnapshot(orgId: org2.id, name: org2.name),
      ],
      createdAt: DateTime(2023, 1, 1),
      email: '',
    );
    singleOrgUser = AppUser(
      name: 'User 3',
      role: AppUserRole.standard,
      assignedOrgs: [OrganizationSnapshot(orgId: org1.id, name: org1.name)],
      createdAt: DateTime(2023, 1, 1),
      email: '',
    );
  });

  Widget createWidgetUnderTest(AppUser user) {
    final mockStatsService = MockPlatformStatsService();
    return MaterialApp(
      home: HomeScreen(
        loggedInUser: user,
        orgService: mockOrgService,
        statsService: mockStatsService,
      ),
    );
  }

  group('HomeScreen Routing Logic', () {
    testWidgets('shows SuperAdminDashboard when user is superAdmin', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(superAdmin));
      expect(find.byType(SuperAdminDashboard), findsOneWidget);
    });

    testWidgets('shows Unassigned View when user has 0 shops', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(unassignedUser));
      expect(
        find.text(
          'Your account is active, but you haven’t been assigned to a shop yet.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    });

    testWidgets(
      'shows OrganizationSelectionScreen when user has multiple shops',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest(multiOrgUser));
        expect(find.byType(OrganizationSelectionScreen), findsOneWidget);
      },
    );
  });

  group('Single Organization Logic (FutureBuilder)', () {
    testWidgets('shows Loading Indicator while fetching organization', (
      tester,
    ) async {
      // Setup the mock to hang/delay
      when(() => mockOrgService.getOrganizationById(any())).thenAnswer((
        _,
      ) async {
        await Future.delayed(const Duration(seconds: 1));
        return null;
      });

      final mockStatsService = MockPlatformStatsService();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            loggedInUser: singleOrgUser,
            orgService: mockOrgService, // Pass the mock here!
            statsService: mockStatsService,
          ),
        ),
      );

      // This check happens on the very first frame where the Future is still pending
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets(
      'shows OrganizationDashboard when data is fetched successfully',
      (tester) async {
        final mockOrg = Organization(
          id: '1',
          name: 'Shop 1',
          createdAt: DateTime(2023, 1, 1),
        );
        when(
          () => mockOrgService.getOrganizationById('1'),
        ).thenAnswer((_) async => mockOrg);

        await tester.pumpWidget(createWidgetUnderTest(singleOrgUser));
        await tester.pump(); // Start future
        await tester.pump(); // Resolve future

        expect(find.byType(OrganizationDashboard), findsOneWidget);
      },
    );

    testWidgets('shows Unassigned View when organization fetch returns null', (
      tester,
    ) async {
      when(
        () => mockOrgService.getOrganizationById('1'),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(createWidgetUnderTest(singleOrgUser));
      await tester.pumpAndSettle();

      expect(
        find.text('Please contact your administrator to get access.'),
        findsOneWidget,
      );
    });
  });

  group('Logout Logic', () {
    testWidgets('cancelling logout dialog stays on screen', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(unassignedUser));

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle(); // Show dialog

      expect(
        find.text('Are you sure you want to sign out of Apoorva Polaris?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    // Note: Testing successful navigation to LoginScreen requires
    // a mock Navigator or checking the widget tree.
    testWidgets('confirming logout calls Auth service and redirects', (
      tester,
    ) async {
      // 1. Create the mock
      final mockAuthService = MockAuthService();
      final mockStatsService = MockPlatformStatsService();

      // 2. Stub the signOut method to do nothing (just return normally)
      when(() => mockAuthService.signOut()).thenAnswer((_) async {});

      // 3. Pass the mock into the widget
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            loggedInUser: unassignedUser,
            orgService: mockOrgService,
            authService: mockAuthService, // Pass it here!
            statsService: mockStatsService,
          ),
        ),
      );

      // Trigger the dialog
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Tap Logout in the dialog
      await tester.tap(find.widgetWithText(TextButton, 'Logout'));
      // 4. IMPORTANT: Use pump() instead of pumpAndSettle() if LoginScreen
      // also has hardcoded Firebase dependencies that might crash.
      await tester.pumpAndSettle();

      // 5. Verify the auth service was actually called
      verify(() => mockAuthService.signOut()).called(1);

      // 6. Verify navigation happened
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
