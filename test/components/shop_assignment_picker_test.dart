import 'dart:async';
import 'package:apoorva_app/components/shop_assignment_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/organization/organization_snapshot.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:apoorva_app/services/user_service.dart';
import 'package:apoorva_app/enum/organization_user_role.dart';

class MockOrgService extends Mock implements OrganizationService {}

class MockUserService extends Mock implements UserService {}

class MockAppUser extends Mock implements AppUser {}

void main() {
  late MockOrgService mockOrgService;
  late MockUserService mockUserService;
  late MockAppUser mockUser;

  late StreamController<List<Organization>> orgController;
  late StreamController<List<OrganizationSnapshot>> mappingController;

  setUpAll(() {
    registerFallbackValue(MockAppUser());
    registerFallbackValue(
      Organization(id: '1', name: 'Test', createdAt: DateTime(2023, 1, 1)),
    );
  });

  setUp(() {
    mockOrgService = MockOrgService();
    mockUserService = MockUserService();
    mockUser = MockAppUser();

    orgController = StreamController<List<Organization>>();
    mappingController = StreamController<List<OrganizationSnapshot>>();

    when(() => mockUser.id).thenReturn('user_123');
    when(() => mockUser.name).thenReturn('Manikanta');
    when(
      () => mockOrgService.getOrganizations(),
    ).thenAnswer((_) => orgController.stream);
    when(
      () => mockUserService.getUserShops(any()),
    ).thenAnswer((_) => mappingController.stream);
  });

  tearDown(() {
    orgController.close();
    mappingController.close();
  });

  Widget createWidget() {
    return MaterialApp(
      home: Scaffold(
        body: ShopAssignmentPicker(
          user: mockUser,
          orgService: mockOrgService,
          userService: mockUserService,
        ),
      ),
    );
  }

  group('ShopAssignmentPicker - Rendering', () {
    testWidgets('shows loading indicator when streams have no data', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders Assigned and Available sections correctly', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      // Provide data to streams
      orgController.add([
        Organization(
          id: 'org_1',
          name: 'Apoorva Shop',
          createdAt: DateTime(2023, 1, 1),
        ),
        Organization(
          id: 'org_2',
          name: 'New Shop',
          createdAt: DateTime(2023, 1, 1),
        ),
      ]);
      mappingController.add([
        OrganizationSnapshot(orgId: 'org_1', name: 'Apoorva Shop'),
      ]);

      await tester.pumpAndSettle();

      expect(find.text('ACTIVE ASSIGNMENTS'), findsOneWidget);
      expect(find.text('AVAILABLE SHOPS'), findsOneWidget);
      expect(find.text('Apoorva Shop'), findsOneWidget);
      expect(find.text('New Shop'), findsOneWidget);
    });
  });

  group('ShopAssignmentPicker - Actions', () {
    testWidgets('handles unmapping a shop', (tester) async {
      when(
        () => mockUserService.unmapUserFromOrganization(
          userId: any(named: 'userId'),
          orgId: any(named: 'orgId'),
        ),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidget());
      orgController.add([
        Organization(
          id: 'org_1',
          name: 'Apoorva Shop',
          createdAt: DateTime(2023, 1, 1),
        ),
      ]);
      mappingController.add([
        OrganizationSnapshot(orgId: 'org_1', name: 'Apoorva Shop'),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();

      verify(
        () => mockUserService.unmapUserFromOrganization(
          userId: 'user_123',
          orgId: 'org_1',
        ),
      ).called(1);
    });

    testWidgets('handles full assignment flow (Select -> Role -> Confirm)', (
      tester,
    ) async {
      // 1. Create a Completer to control the timing
      final mapCompleter = Completer<void>();

      when(
        () => mockUserService.mapUserToOrganization(
          fullUser: any(named: 'fullUser'),
          fullOrg: any(named: 'fullOrg'),
          orgRole: any(named: 'orgRole'),
        ),
      ).thenAnswer(
        (_) => mapCompleter.future,
      ); // It won't finish until we say so

      await tester.pumpWidget(createWidget());
      orgController.add([
        Organization(
          id: 'org_2',
          name: 'New Shop',
          createdAt: DateTime(2023, 1, 1),
        ),
      ]);
      mappingController.add([]);
      await tester.pumpAndSettle();

      // Trigger the assignment flow
      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();

      // Select Role
      await tester.tap(
        find.byType(DropdownButtonFormField<OrganizationUserRole>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ADMIN').last);
      await tester.pumpAndSettle();

      // 2. Tap Confirm
      await tester.tap(find.byIcon(Icons.check_circle).last);

      // 3. Pump once to trigger the build with _isSaving = true
      await tester.pump();

      // NOW the indicator should be there because mapCompleter hasn't finished!
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // 4. Manually finish the service call
      mapCompleter.complete();

      // 5. Clean up the rest of the animations
      await tester.pumpAndSettle();

      // Verify it's gone now
      expect(find.byType(LinearProgressIndicator), findsNothing);

      verify(
        () => mockUserService.mapUserToOrganization(
          fullUser: mockUser,
          fullOrg: any(named: 'fullOrg'),
          orgRole: 'admin',
        ),
      ).called(1);
    });

    testWidgets('handles cancel assignment selection', (tester) async {
      await tester.pumpWidget(createWidget());
      orgController.add([
        Organization(
          id: 'org_2',
          name: 'New Shop',
          createdAt: DateTime(2023, 1, 1),
        ),
      ]);
      mappingController.add([]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();
      expect(
        find.byType(DropdownButtonFormField<OrganizationUserRole>),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.cancel_outlined));
      await tester.pumpAndSettle();

      expect(
        find.byType(DropdownButtonFormField<OrganizationUserRole>),
        findsNothing,
      );
    });

    testWidgets('handles mapping error gracefully', (tester) async {
      when(
        () => mockUserService.mapUserToOrganization(
          fullUser: any(named: 'fullUser'),
          fullOrg: any(named: 'fullOrg'),
          orgRole: any(named: 'orgRole'),
        ),
      ).thenThrow(Exception('Network Error'));

      await tester.pumpWidget(createWidget());
      orgController.add([
        Organization(
          id: 'org_2',
          name: 'New Shop',
          createdAt: DateTime(2023, 1, 1),
        ),
      ]);
      mappingController.add([]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Assign'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_circle).last);
      await tester.pumpAndSettle();

      // Verify that saving state is reset
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
