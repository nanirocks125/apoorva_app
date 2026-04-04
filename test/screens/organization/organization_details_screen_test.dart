import 'dart:async';
import 'package:apoorva_app/screens/organization/organization_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/account.dart';
import 'package:apoorva_app/enum/account_type.dart';
import 'package:apoorva_app/model/user/app_user_snapshot.dart';
import 'package:apoorva_app/services/user_service.dart';
import 'package:apoorva_app/components/user_assignment_picker.dart';

class MockUserService extends Mock implements UserService {}

void main() {
  late MockUserService mockUserService;
  late Organization baseOrg;

  setUp(() {
    mockUserService = MockUserService();

    // 1. Stub the staff list (you likely already have this)
    when(
      () => mockUserService.getOrganizationUsers(any()),
    ).thenAnswer((_) => Stream.value([]));

    // 2. THE FIX: Stub the global users list
    // Even if you return an empty list, it MUST be a Stream, not null.
    when(
      () => mockUserService.getAllUsersGlobal(),
    ).thenAnswer((_) => Stream.value([]));
    baseOrg = Organization(
      id: 'org_1',
      name: 'Test Shop',
      status: 'Active',
      createdAt: DateTime(2024, 1, 1, 10, 30),
      minVersion: '2.0.0',
      accounts: [
        Account(name: 'Cash', type: AccountType.cash, currentBalance: 100.0),
        Account(name: 'HDFC', type: AccountType.bank, currentBalance: 500.0),
        Account(name: 'GPay', type: AccountType.upi, currentBalance: 50.0),
      ],
    );

    // Default stub for staff stream
    when(
      () => mockUserService.getOrganizationUsers(any()),
    ).thenAnswer((_) => Stream.value([]));
  });

  Widget createWidget(Organization org) {
    return MaterialApp(
      home: OrganizationDetailsScreen(org: org, userService: mockUserService),
    );
  }

  group('Identity & Financials Scenarios', () {
    testWidgets('renders all identity details correctly', (tester) async {
      await tester.pumpWidget(createWidget(baseOrg));

      expect(find.text('Test Shop'), findsWidgets);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('01 Jan 2024, 10:30 AM'), findsOneWidget);
      expect(find.text('2.0.0'), findsOneWidget);
    });

    testWidgets('calculates total balance correctly', (tester) async {
      await tester.pumpWidget(createWidget(baseOrg));
      // 100 + 500 + 50 = 650
      expect(find.text('Total: ₹650.00'), findsOneWidget);
    });

    testWidgets('shows empty state when no accounts exist', (tester) async {
      final emptyOrg = baseOrg.copyWith(accounts: []);
      await tester.pumpWidget(createWidget(emptyOrg));
      expect(find.text('No accounts created by owner yet.'), findsOneWidget);
    });

    testWidgets('covers all account type icon/color branches', (tester) async {
      await tester.pumpWidget(createWidget(baseOrg));

      expect(find.byIcon(Icons.payments_outlined), findsOneWidget); // Cash
      expect(
        find.byIcon(Icons.account_balance_outlined),
        findsOneWidget,
      ); // Bank
      expect(
        find.byIcon(Icons.qr_code_scanner_outlined),
        findsOneWidget,
      ); // UPI
    });
  });

  group('Staff Section Scenarios', () {
    testWidgets('shows loading indicator while fetching staff', (tester) async {
      final completer = Completer<List<AppUserSnapshot>>();
      when(
        () => mockUserService.getOrganizationUsers(any()),
      ).thenAnswer((_) => Stream.fromFuture(completer.future));

      await tester.pumpWidget(createWidget(baseOrg));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty staff message when list is empty', (tester) async {
      await tester.pumpWidget(createWidget(baseOrg));
      await tester.pump(); // Resolve stream
      expect(find.text('No staff assigned'), findsOneWidget);
    });

    testWidgets('renders staff list with correct role colors', (tester) async {
      final staff = [
        AppUserSnapshot(
          uid: '1',
          name: 'Alice',
          email: 'a@e.com',
          orgRole: 'admin',
        ),
        AppUserSnapshot(
          uid: '2',
          name: 'Bob',
          email: 'b@e.com',
          orgRole: 'manager',
        ),
        AppUserSnapshot(
          uid: '3',
          name: 'Charlie',
          email: 'c@e.com',
          orgRole: 'staff',
        ),
      ];

      when(
        () => mockUserService.getOrganizationUsers(any()),
      ).thenAnswer((_) => Stream.value(staff));

      await tester.pumpWidget(createWidget(baseOrg));
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('MANAGER'), findsOneWidget);
      expect(find.text('STAFF'), findsOneWidget);

      // Verify initial letter logic
      expect(find.text('A'), findsOneWidget);
    });
  });

  group('Interactions', () {
    testWidgets('opens UserAssignmentPicker in BottomSheet', (tester) async {
      await tester.pumpWidget(createWidget(baseOrg));

      await tester.tap(find.byIcon(Icons.person_add_alt_1));
      await tester.pumpAndSettle();

      expect(find.byType(UserAssignmentPicker), findsOneWidget);
    });

    testWidgets('triggers navigateToEdit (logic coverage)', (tester) async {
      await tester.pumpWidget(createWidget(baseOrg));
      await tester.tap(find.byIcon(Icons.edit_note));
      // Note: Since _navigateToEdit is empty, we just verify the tap doesn't crash
      await tester.pump();
    });
  });
}
