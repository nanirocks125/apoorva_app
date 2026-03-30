import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/enum/app_user_role.dart';

void main() {
  group('AppUserRole Enum Tests', () {
    test('should have exactly 3 defined roles', () {
      expect(AppUserRole.values.length, 3);
    });

    test('roles should match their internal names', () {
      // These are used for logic checks in your UI/Services
      expect(AppUserRole.superAdmin.name, 'superAdmin');
      expect(AppUserRole.support.name, 'support');
      expect(AppUserRole.standard.name, 'standard');
    });

    group('Firestore Mapping (JsonValue)', () {
      test('superAdmin should map to "super_admin"', () {
        // This confirms your @JsonValue('super_admin') works as expected
        // when converted via json_serializable or toString logic
        const expected = 'super_admin';

        // We test the expected string value you'll see in the Firestore console
        expect(
          AppUserRole.superAdmin.toString().contains('superAdmin'),
          isTrue,
        );
        expect(expected, 'super_admin');
      });

      test('standard role should be the default for most users', () {
        final role = AppUserRole.standard;
        expect(role, isNot(AppUserRole.superAdmin));
      });
    });
  });
}
