import 'dart:async';
import 'package:apoorva_app/components/user_assignment_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/model/user/app_user_snapshot.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/services/user_service.dart';
import 'package:apoorva_app/enum/organization_user_role.dart';

// Mocks
class MockUserService extends Mock implements UserService {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserService mockUserService;
  late MockNavigatorObserver mockObserver;
  late Organization testOrg;
  late StreamController<List<AppUserSnapshot>> staffController;
  late StreamController<List<AppUser>> globalController;

  setUpAll(() {
    registerFallbackValue(
      AppUser(id: '1', name: 'N', email: 'e', createdAt: DateTime(2021, 1, 1)),
    );
    registerFallbackValue(
      Organization(id: '1', name: 'O', createdAt: DateTime(2023, 1, 1)),
    );
    registerFallbackValue(FakeRoute());
  });

  setUp(() {
    mockUserService = MockUserService();
    mockObserver = MockNavigatorObserver();
    testOrg = Organization(
      id: 'org_123',
      name: 'Apoorva Shop',
      createdAt: DateTime(2023, 1, 1),
    );
    staffController = StreamController<List<AppUserSnapshot>>();
    globalController = StreamController<List<AppUser>>();

    when(
      () => mockUserService.getOrganizationUsers(any()),
    ).thenAnswer((_) => staffController.stream);
    when(
      () => mockUserService.getAllUsersGlobal(),
    ).thenAnswer((_) => globalController.stream);
  });

  tearDown(() {
    staffController.close();
    globalController.close();
  });

  Widget createWidget() => MaterialApp(
    navigatorObservers: [mockObserver],
    home: Scaffold(
      body: UserAssignmentPicker(
        organization: testOrg,
        userService: mockUserService,
      ),
    ),
  );

  group('UserAssignmentPicker - 100% Coverage Suite', () {
    testWidgets('shows loading while waiting for streams', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders Active Staff and Available Users correctly', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      globalController.add([
        AppUser(
          id: 'u1',
          name: 'Manikanta',
          email: 'm@t.com',
          createdAt: DateTime(2021, 1, 1),
        ),
      ]);
      staffController.add([
        AppUserSnapshot(uid: 'u1', name: 'Manikanta', email: 'm@t.com'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('ACTIVE STAFF'), findsOneWidget);
      expect(find.text('Manikanta'), findsOneWidget);
    });

    testWidgets('adds a user to organization successfully', (tester) async {
      final mapCompleter = Completer<void>();

      when(
        () => mockUserService.mapUserToOrganization(
          fullUser: any(named: 'fullUser'),
          fullOrg: any(named: 'fullOrg'),
          orgRole: any(named: 'orgRole'),
        ),
      ).thenAnswer((_) => mapCompleter.future);

      await tester.pumpWidget(createWidget());
      globalController.add([
        AppUser(
          id: 'u2',
          name: 'Available',
          email: 'a@e.com',
          createdAt: DateTime(2021, 1, 1),
        ),
      ]);
      staffController.add([]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // 1. Dropdown ఓపెన్ చేసి ఐటమ్ సెలెక్ట్ చెయ్
      await tester.tap(
        find.byType(DropdownButtonFormField<OrganizationUserRole>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ADMIN').last);
      await tester.pumpAndSettle();
      // ఇక్కడ Dropdown క్లోజ్ అవ్వడానికి ఒక POP జరిగింది.

      // 2. CRITICAL: ఇక్కడ క్లియర్ చేయాలి!
      // దీనివల్ల Dropdown pop ని ఇగ్నోర్ చేసి, కేవలం మెయిన్ కోడ్ pop ని కౌంట్ చేస్తుంది.
      clearInteractions(mockObserver);

      // 3. Confirm బటన్ టాప్ చెయ్
      await tester.tap(find.byIcon(Icons.check_circle).last);

      await tester.pump(); // Loading చూపిస్తుంది
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      mapCompleter.complete();
      await tester.pumpAndSettle();

      // ఇక్కడ కౌంట్ కరెక్ట్ గా 1 వస్తుంది
      verify(() => mockObserver.didPop(any(), any())).called(1);
    });

    testWidgets('removes a staff member successfully with loading state', (
      tester,
    ) async {
      final unmapCompleter = Completer<void>();
      when(
        () => mockUserService.unmapUserFromOrganization(
          userId: any(named: 'userId'),
          orgId: any(named: 'orgId'),
        ),
      ).thenAnswer((_) => unmapCompleter.future);

      await tester.pumpWidget(createWidget());
      globalController.add([
        AppUser(
          id: 'u1',
          name: 'Active',
          email: 'e@e.com',
          createdAt: DateTime(2021, 1, 1),
        ),
      ]);
      staffController.add([
        AppUserSnapshot(uid: 'u1', name: 'Active', email: 'e@e.com'),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      unmapCompleter.complete();
      await tester.pumpAndSettle();
      expect(find.text('Staff member removed successfully'), findsOneWidget);
    });

    testWidgets('handles unmapping error', (tester) async {
      when(
        () => mockUserService.unmapUserFromOrganization(
          userId: any(named: 'userId'),
          orgId: any(named: 'orgId'),
        ),
      ).thenThrow('Timeout');

      await tester.pumpWidget(createWidget());
      globalController.add([
        AppUser(
          id: 'u1',
          name: 'A',
          email: 'e',
          createdAt: DateTime(2021, 1, 1),
        ),
      ]);
      staffController.add([AppUserSnapshot(uid: 'u1', name: 'A', email: 'e')]);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Error removing staff: Timeout'),
        findsOneWidget,
      );
    });

    testWidgets('cancels add flow', (tester) async {
      await tester.pumpWidget(createWidget());
      globalController.add([
        AppUser(
          id: 'u2',
          name: 'Available',
          email: 'a@e.com',
          createdAt: DateTime(2021, 1, 1),
        ),
      ]);
      staffController.add([]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.cancel_outlined));
      await tester.pumpAndSettle();
      expect(
        find.byType(DropdownButtonFormField<OrganizationUserRole>),
        findsNothing,
      );
    });
  });
}
