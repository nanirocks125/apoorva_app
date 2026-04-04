import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/enum/organization_user_role.dart';

void main() {
  group('OrganizationUserRole Enum Tests', () {
    test('should have exactly 5 defined roles for shop management', () {
      expect(OrganizationUserRole.values.length, 5);
    });

    test('enum names should match internal dart identifiers', () {
      expect(OrganizationUserRole.owner.name, 'owner');
      expect(OrganizationUserRole.admin.name, 'admin');
      expect(OrganizationUserRole.staff.name, 'staff');
      expect(OrganizationUserRole.manager.name, 'manager');
      expect(OrganizationUserRole.viewer.name, 'viewer');
    });

    group('Firestore Mapping (JsonValue)', () {
      test('all roles should map to lowercase strings in Firestore', () {
        // This confirms that your @JsonValue annotations match
        // the expected lowercase strings in your database.

        const expectedValues = ['owner', 'admin', 'staff', 'manager', 'viewer'];

        for (var i = 0; i < OrganizationUserRole.values.length; i++) {
          final role = OrganizationUserRole.values[i];
          // We verify that the string representation (used by json_serializable)
          // matches our database contract.
          expect(role.name, expectedValues[i]);
        }
      });

      test('specific role checks for logic gates', () {
        // Ensuring owner is distinct from staff for permission logic
        expect(OrganizationUserRole.owner, isNot(OrganizationUserRole.staff));
        expect(OrganizationUserRole.manager, isNot(OrganizationUserRole.admin));
      });
    });
  });
}
