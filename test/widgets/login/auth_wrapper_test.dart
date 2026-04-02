import 'package:apoorva_app/enum/app_user_role.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart'; // Correct for mocking
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/providers/auth_provider.dart';
import 'package:apoorva_app/auth_wrapper.dart'; // Verify this path matches your project
import 'package:apoorva_app/screens/auth/login_screen.dart';
import 'package:apoorva_app/screens/dashboard/super_admin_dashboard.dart';
import 'package:apoorva_app/screens/home_screen.dart';
import 'package:apoorva_app/model/user/app_user.dart';

// --- MOCK CLASS ---
class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  // REMOVED: setupFirebaseCoreMocks() from here.
  // It must stay inside setUpAll after the binding is ready.

  late MockAuthProvider mockAuthProvider;

  setUpAll(() async {
    // 1. Initialize the Test Binding first
    TestWidgetsFlutterBinding.ensureInitialized();

    // 2. Setup the Firebase Mocks
    setupFirebaseCoreMocks();

    // 3. Initialize Firebase
    await Firebase.initializeApp();
  });

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    // Always provide a default status to prevent "missing stub" errors
    when(() => mockAuthProvider.status).thenReturn(AuthStatus.initial);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuthProvider,
        child: const AuthWrapper(),
      ),
    );
  }

  group('AuthWrapper Widget Tests -', () {
    testWidgets('shows CircularProgressIndicator when status is loading', (
      tester,
    ) async {
      when(() => mockAuthProvider.status).thenReturn(AuthStatus.loading);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Triggers the first frame

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows LoginScreen when status is unauthenticated', (
      tester,
    ) async {
      when(
        () => mockAuthProvider.status,
      ).thenReturn(AuthStatus.unauthenticated);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('shows SuperAdminDashboard when role is super_admin', (
      tester,
    ) async {
      // NOTE: Using explicit Enum names instead of shorthand .superAdmin
      // for better compiler stability in tests.
      final adminUser = AppUser(
        id: '1', // Check if your model uses 'uid' or 'id'
        email: 'admin@test.com',
        role: AppUserRole.superAdmin,
        name: 'Test Admin',
        createdAt: DateTime.now(),
      );

      when(() => mockAuthProvider.status).thenReturn(AuthStatus.authenticated);
      when(() => mockAuthProvider.user).thenReturn(adminUser);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(SuperAdminDashboard), findsOneWidget);
    });

    testWidgets('shows HomeScreen for standard users', (tester) async {
      final staffUser = AppUser(
        id: '2',
        email: 'staff@test.com',
        role: AppUserRole.standard,
        name: 'Test Staff',
        createdAt: DateTime.now(),
      );

      when(() => mockAuthProvider.status).thenReturn(AuthStatus.authenticated);
      when(() => mockAuthProvider.user).thenReturn(staffUser);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
