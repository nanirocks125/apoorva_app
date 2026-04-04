import 'package:apoorva_app/components/global_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/enum/app_user_role.dart';

// Mocks
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late AppUser adminUser;
  late AppUser regularUser;
  late MockNavigatorObserver mockObserver;
  bool logoutCalled = false;

  setUpAll(() {
    registerFallbackValue(FakeRoute());
  });

  setUp(() {
    logoutCalled = false;
    mockObserver = MockNavigatorObserver();

    adminUser = AppUser(
      name: 'Admin User',
      email: 'admin@test.com',
      role: AppUserRole.superAdmin,
      createdAt: DateTime(2020, 1, 1),
    );

    regularUser = AppUser(
      name: 'Regular User',
      email: 'user@test.com',
      role: AppUserRole
          .standard, // Assuming anything not superAdmin is regular here
      createdAt: DateTime(2020, 1, 1),
    );
  });

  Widget createWidgetUnderTest({required AppUser user}) {
    return MaterialApp(
      navigatorObservers: [mockObserver],
      // REMOVE the '/' route here
      routes: {
        '/users': (_) => const Scaffold(),
        '/organizations': (_) => const Scaffold(),
        '/profile': (_) => const Scaffold(),
        '/settings': (_) => const Scaffold(),
      },
      // Keep 'home' as the entry point for the test
      home: Scaffold(
        drawer: GlobalDrawer(),
        body: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
    );
  }

  group('GlobalDrawer UI Rendering', () {
    testWidgets('renders user info and admin sections for Super Admin', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(user: adminUser));
      await tester.tap(find.byType(IconButton)); // Open drawer
      await tester.pumpAndSettle();

      // Check Header
      expect(find.text('Admin User'), findsOneWidget);
      expect(find.text('admin@test.com'), findsOneWidget);
      expect(find.text('A'), findsOneWidget); // Initial

      // Check Admin Section
      expect(find.text('MANAGEMENT'), findsOneWidget);
      expect(find.text('Global Users'), findsOneWidget);
      expect(find.text('Organizations'), findsOneWidget);
    });

    testWidgets('hides admin sections for regular users', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(user: regularUser));
      await tester.tap(find.byType(IconButton)); // Open drawer
      await tester.pumpAndSettle();

      expect(find.text('MANAGEMENT'), findsNothing);
      expect(find.text('Global Users'), findsNothing);
      expect(find.text('Organizations'), findsNothing);

      // Account section should still exist
      expect(find.text('ACCOUNT'), findsOneWidget);
    });
  });

  group('GlobalDrawer Interactions & Navigation', () {
    testWidgets('Home Dashboard closes the drawer', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(user: adminUser));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home Dashboard'));
      await tester.pumpAndSettle();

      // Drawer should be closed (Scaffold.of(context).isDrawerOpen would be false)
      expect(find.byType(GlobalDrawer), findsNothing);
    });

    testWidgets('navigates to Global Users and closes drawer', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(user: adminUser));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Global Users'));
      await tester.pumpAndSettle();

      verify(() => mockObserver.didPush(any(), any())).called(greaterThan(0));
      expect(find.byType(GlobalDrawer), findsNothing);
    });

    testWidgets('navigates to Organizations', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(user: adminUser));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Organizations'));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalDrawer), findsNothing);
    });

    testWidgets('navigates to My Profile', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(user: regularUser));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalDrawer), findsNothing);
    });

    testWidgets('navigates to App Settings', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(user: regularUser));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('App Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalDrawer), findsNothing);
    });

    testWidgets('triggers onLogout when Sign Out is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(user: regularUser));
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(logoutCalled, isTrue);
    });
  });
}
