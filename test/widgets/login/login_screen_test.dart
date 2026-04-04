import 'dart:async';

import 'package:apoorva_app/enum/app_user_role.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/providers/auth_provider.dart';

// 1. Mock AuthProvider
class MockAuthProvider extends Mock implements AuthProvider {}

// 2. Mock Navigator (to verify navigation)
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late MockAuthProvider mockAuth;
  late MockNavigatorObserver mockObserver;
  setUpAll(() {
    registerFallbackValue(FakeRoute());
  });

  setUp(() {
    mockAuth = MockAuthProvider();
    mockObserver = MockNavigatorObserver();

    // Register fallback for navigation route if needed
    registerFallbackValue(Route<dynamic>);
  });

  // Helper widget to wrap the LoginScreen
  Widget createLoginScreen() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: mockAuth,
      child: MaterialApp(
        home: const LoginScreen(),
        navigatorObservers: [mockObserver],
        routes: {'/home': (context) => const Scaffold(body: Text('Home Page'))},
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('Initial state checks (Debug Mode defaults)', (tester) async {
      await tester.pumpWidget(createLoginScreen());

      // Check Logo and Title
      expect(find.byIcon(Icons.storefront), findsOneWidget);
      expect(find.text('Apoorva'), findsOneWidget);

      // Check if debug mode values are populated
      // Note: This only works if your test runs in kDebugMode
      expect(find.text('lavanya@gmail.com'), findsOneWidget);
      expect(find.text('Apoorva@123'), findsOneWidget);
    });

    testWidgets('Show error messages on empty/invalid input', (tester) async {
      await tester.pumpWidget(createLoginScreen());

      // Clear the default values first
      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.enterText(find.byType(TextFormField).last, '123');

      await tester.tap(find.text('Login to Dashboard'));
      await tester.pump(); // Validation triggers frame change

      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Password too short'), findsOneWidget);
    });

    testWidgets('Successful login flow and navigation', (tester) async {
      // 1. Create a Completer to control the mock finish time
      final loginCompleter = Completer<void>();

      when(() => mockAuth.signIn(any(), any())).thenAnswer(
        (_) => loginCompleter.future,
      ); // ఇక్కడ వెంటనే complete అవ్వదు

      await tester.pumpWidget(createLoginScreen());

      // 2. Debug mode values మీద rely అవ్వకుండా, explicitly text enter చేయడం మంచిది
      await tester.enterText(
        find.byType(TextFormField).first,
        'lavanya@gmail.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'Apoorva@123');

      await tester.tap(find.text('Login to Dashboard'));

      // 3. First pump: Loading state ని trigger చేస్తుంది
      await tester.pump();

      // ఇక్కడ indicator కచ్చితంగా కనిపిస్తుంది
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 4. Now complete the future
      loginCompleter.complete();

      // 5. Wait for all animations and navigation to finish
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('Show SnackBar on login failure', (tester) async {
      // Mock failure
      when(
        () => mockAuth.signIn(any(), any()),
      ).thenThrow('Invalid Credentials');

      await tester.pumpWidget(createLoginScreen());

      await tester.tap(find.text('Login to Dashboard'));
      await tester.pumpAndSettle(); // Wait for catch block and SnackBar

      expect(find.text('Invalid Credentials'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  testWidgets('Verify AppUser is passed as argument to /home on success', (
    tester,
  ) async {
    // 1. Arrange - Create a mock user
    // Assuming AppUser has these fields based on your previous snippets
    final testUser = AppUser(
      name: 'Manikanta',
      role: AppUserRole.standard,
      assignedOrgs: [],
      email: '',
      createdAt: DateTime(2023, 1, 1),
    );

    // Mock signIn to succeed and authProvider.user to return our testUser
    when(() => mockAuth.signIn(any(), any())).thenAnswer((_) async => {});
    when(() => mockAuth.user).thenReturn(testUser);

    await tester.pumpWidget(createLoginScreen());

    // 2. Act
    // Explicitly enter text if needed, or rely on debug defaults
    await tester.tap(find.text('Login to Dashboard'));

    // Wait for the async logic and navigation animation to finish
    await tester.pumpAndSettle();

    // 3. Assert - Capture the navigation event
    // Since you used pushReplacementNamed, we verify didReplace
    final captured = verify(
      () => mockObserver.didReplace(
        newRoute: captureAny(named: 'newRoute'),
        oldRoute: any(named: 'oldRoute'),
      ),
    ).captured;

    // Check if the captured route has the correct arguments
    final Route<dynamic> route = captured.first as Route<dynamic>;
    final dynamic args = route.settings.arguments;

    expect(route.settings.name, equals('/home'));
    expect(args, isNotNull);
    expect(args, isA<AppUser>());

    final AppUser passedUser = args as AppUser;
    expect(passedUser.name, equals('Manikanta'));
    print('Verified: User ${passedUser.name} passed to HomeScreen');
  });
}
