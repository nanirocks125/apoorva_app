import 'dart:async';
import 'package:apoorva_app/enum/app_user_role.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/model/user/app_user_snapshot.dart';
import 'package:apoorva_app/screens/home/user/users_screen.dart';
import 'package:apoorva_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockUserService extends Mock implements UserService {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockUserService mockUserService;
  late MockNavigatorObserver mockObserver;
  late Organization testOrg;

  setUpAll(() {
    registerFallbackValue(MaterialPageRoute(builder: (_) => Container()));
  });

  setUp(() {
    mockUserService = MockUserService();
    mockObserver = MockNavigatorObserver();
    testOrg = Organization(
      id: 'org1',
      name: 'Test Shop',
      createdAt: DateTime.now(),
    );
  });

  Widget createWidgetUnderTest({Organization? org}) {
    return MaterialApp(
      navigatorObservers: [mockObserver],
      home: UserScreen(org: org, userService: mockUserService),
    );
  }

  group('UserScreen Rendering Logic', () {
    testWidgets('shows loading indicator when stream is waiting', (
      tester,
    ) async {
      when(
        () => mockUserService.getAllUsersGlobal(),
      ).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when stream has error', (tester) async {
      when(
        () => mockUserService.getAllUsersGlobal(),
      ).thenAnswer((_) => Stream.error('Database Error'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      expect(find.text('Error: Database Error'), findsOneWidget);
    });

    testWidgets('shows empty state when no users exist', (tester) async {
      when(
        () => mockUserService.getAllUsersGlobal(),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('No users found'), findsOneWidget);
      expect(find.byIcon(Icons.group_add_outlined), findsOneWidget);
    });

    testWidgets('renders Global Users title when org is null', (tester) async {
      when(
        () => mockUserService.getAllUsersGlobal(),
      ).thenAnswer((_) => Stream.value([]));
      await tester.pumpWidget(createWidgetUnderTest(org: null));
      expect(find.text('Global Users'), findsOneWidget);
    });

    testWidgets('renders Org Staff title when org is provided', (tester) async {
      when(
        () => mockUserService.getOrganizationUsers(any()),
      ).thenAnswer((_) => Stream.value([]));
      await tester.pumpWidget(createWidgetUnderTest(org: testOrg));
      expect(find.text('Test Shop Staff'), findsOneWidget);
    });
  });

  group('Data Extraction & Role Colors', () {
    testWidgets('renders list with AppUserSnapshot (Org Context)', (
      tester,
    ) async {
      final snapshot = AppUserSnapshot(
        uid: '123',
        name: 'John Staff',
        email: 'john@test.com',
        orgRole: 'staff',
      );

      when(
        () => mockUserService.getOrganizationUsers('org1'),
      ).thenAnswer((_) => Stream.value([snapshot]));

      await tester.pumpWidget(createWidgetUnderTest(org: testOrg));
      await tester.pump();

      expect(find.text('John Staff'), findsOneWidget);
      expect(find.text('STAFF'), findsOneWidget);
      // Verify role-based color logic for Staff (Green)
      final container = tester.widget<Container>(
        find.ancestor(of: find.text('STAFF'), matching: find.byType(Container)),
      );
      expect(
        (container.decoration as BoxDecoration).color,
        Colors.green.shade600.withOpacity(0.1),
      );
    });

    testWidgets(
      'renders list with AppUser (Global Context) and handles default role color',
      (tester) async {
        final user = AppUser(
          id: '456',
          name: 'Unknown User',
          email: 'unknown@test.com',
          role: AppUserRole
              .standard, // Will fall into 'default' case in _getRoleColor
          createdAt: DateTime.now(),
        );

        when(
          () => mockUserService.getAllUsersGlobal(),
        ).thenAnswer((_) => Stream.value([user]));

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.text('Unknown User'), findsOneWidget);
        final avatarText = tester.widget<Text>(
          find.descendant(
            of: find.byType(CircleAvatar),
            matching: find.byType(Text),
          ),
        );
        // Standard role should result in grey color
        expect(avatarText.style?.color, Colors.grey.shade400);
      },
    );
  });
}
