import 'package:apoorva_app/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  group('AuthService Unit Tests', () {
    test('signOut should successfully clear the current session', () async {
      // 1. Setup: Create a mock user and sign them in
      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'test_uid_123',
        email: 'tester@example.com',
      );

      final mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      final authService = AuthService(auth: mockAuth);

      // 2. Verify we start signed in
      expect(mockAuth.currentUser, isNotNull);
      expect(mockAuth.currentUser?.uid, 'test_uid_123');

      // 3. Execute the sign out
      await authService.signOut();

      // 4. Verify the session is cleared
      expect(mockAuth.currentUser, isNull);
    });
  });
}
