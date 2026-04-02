import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:apoorva_app/services/user_service.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/providers/auth_provider.dart';

// --- MOCK CLASSES ---
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockUserService extends Mock implements UserService {}

void main() {
  late AuthProvider authProvider;
  late MockFirebaseAuth mockAuth;
  late MockUserService mockUserService;
  late MockUser mockFirebaseUser;

  // Constants for testing
  const tEmail = 'test@apoorva.com';
  const tPassword = 'password123';
  const tUid = 'unique_uid_123';
  final tAppUser = AppUser(
    id: tUid,
    email: tEmail,
    role: .standard,
    name: '',
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUserService = MockUserService();
    mockFirebaseUser = MockUser();

    // Default setup: No user logged in
    when(() => mockAuth.currentUser).thenReturn(null);

    authProvider = AuthProvider(auth: mockAuth, userService: mockUserService);
  });

  group('AuthProvider Initialization -', () {
    test(
      'Initial status should be unauthenticated when no current user exists',
      () async {
        expect(authProvider.status, AuthStatus.unauthenticated);
        expect(authProvider.user, null);
      },
    );

    test(
      'Should authenticate automatically if currentUser exists on startup',
      () async {
        // Arrange
        when(() => mockAuth.currentUser).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn(tUid);
        when(
          () => mockUserService.getUserById(tUid),
        ).thenAnswer((_) async => tAppUser);

        // Re-initialize to trigger the constructor logic again
        authProvider = AuthProvider(
          auth: mockAuth,
          userService: mockUserService,
        );

        // Wait for the internal async _initialize to finish
        await Future.delayed(Duration.zero);

        // Assert
        expect(authProvider.status, AuthStatus.authenticated);
        expect(authProvider.user, tAppUser);
      },
    );
  });

  group('signIn -', () {
    test('Should set status to authenticated on successful login', () async {
      // Arrange
      final mockCredential = MockUserCredential();
      when(() => mockCredential.user).thenReturn(mockFirebaseUser);
      when(() => mockFirebaseUser.uid).thenReturn(tUid);

      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        ),
      ).thenAnswer((_) async => mockCredential);
      when(
        () => mockUserService.getUserById(tUid),
      ).thenAnswer((_) async => tAppUser);

      // Act
      await authProvider.signIn(tEmail, tPassword);

      // Assert
      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.user, tAppUser);
      verify(
        () => mockAuth.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        ),
      ).called(1);
    });

    test(
      'Should throw error and set unauthenticated when Firebase login fails',
      () async {
        // Arrange
        when(
          () => mockAuth.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          ),
        ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

        // Act & Assert
        expect(
          () => authProvider.signIn(tEmail, tPassword),
          throwsA(contains('Incorrect password')),
        );
        expect(authProvider.status, AuthStatus.unauthenticated);
      },
    );

    test(
      'Should throw error and logout if user profile is missing in DB',
      () async {
        // Arrange
        final mockCredential = MockUserCredential();
        when(() => mockCredential.user).thenReturn(mockFirebaseUser);
        when(() => mockFirebaseUser.uid).thenReturn(tUid);

        when(
          () => mockAuth.signInWithEmailAndPassword(
            email: tEmail,
            password: tPassword,
          ),
        ).thenAnswer((_) async => mockCredential);

        // Return null to trigger the "profile not found" logic
        when(
          () => mockUserService.getUserById(tUid),
        ).thenAnswer((_) async => null);

        when(() => mockAuth.signOut()).thenAnswer((_) async => {});

        // Act & Assert
        // 1. Use expectLater and AWAIT it to ensure the async process finishes
        // 1. Use expectLater and AWAIT it to ensure the async process finishes
        await expectLater(
          authProvider.signIn(tEmail, tPassword),
          // We check if it's an Exception AND if its toString contains our text
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('User profile not found'),
            ),
          ),
        );

        // 2. Now that the flow is finished, check if signOut was called
        verify(() => mockAuth.signOut()).called(1);

        expect(authProvider.status, AuthStatus.unauthenticated);
      },
    );
  });

  group('logout -', () {
    test('Should clear user and sign out from Firebase', () async {
      // Arrange
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});

      // Act
      await authProvider.logout();

      // Assert
      expect(authProvider.user, null);
      expect(authProvider.status, AuthStatus.unauthenticated);
      verify(() => mockAuth.signOut()).called(1);
    });
  });
}
