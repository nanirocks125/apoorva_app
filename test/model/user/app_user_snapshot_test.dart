import 'package:apoorva_app/model/user/app_user_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUserSnapshot Model Tests', () {
    group('Constructor & Initialization', () {
      test('should initialize with all required fields', () {
        final user = AppUserSnapshot(
          uid: 'user_123',
          name: 'Manikanta',
          email: 'manikanta@apoorva.com',
          orgRole: 'owner',
        );

        expect(user.uid, 'user_123');
        expect(user.name, 'Manikanta');
        expect(user.email, 'manikanta@apoorva.com');
        expect(user.orgRole, 'owner');
      });

      test('should apply the default role "staff" if none is provided', () {
        final user = AppUserSnapshot(
          uid: 'user_456',
          name: 'Staff Member',
          email: 'staff@apoorva.com',
        );

        // Verifying the default value set in the constructor
        expect(user.orgRole, 'staff');
      });
    });

    group('JSON Serialization', () {
      test('toJson should convert the object into a valid Map', () {
        final user = AppUserSnapshot(
          uid: 'uid_789',
          name: 'Lavanya',
          email: 'lavanya@gmail.com',
          orgRole: 'manager',
        );

        final json = user.toJson();

        expect(json['uid'], 'uid_789');
        expect(json['name'], 'Lavanya');
        expect(json['email'], 'lavanya@gmail.com');
        expect(json['orgRole'], 'manager');
      });

      test('fromJson should correctly recreate the object from a Map', () {
        final json = {
          'uid': 'uid_001',
          'name': 'New Joiner',
          'email': 'new@apoorva.com',
          'orgRole': 'sales_staff',
        };

        final user = AppUserSnapshot.fromJson(json);

        expect(user.uid, 'uid_001');
        expect(user.name, 'New Joiner');
        expect(user.orgRole, 'sales_staff');
      });

      test('fromJson should handle missing orgRole by using the default', () {
        final json = {
          'uid': 'uid_002',
          'name': 'Unknown Staff',
          'email': 'unknown@apoorva.com',
          // orgRole is missing in the incoming JSON
        };

        final user = AppUserSnapshot.fromJson(json);

        expect(user.orgRole, 'staff');
      });
    });
  });
}
