import 'package:apoorva_app/model/user/app_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apoorva_app/model/organization/organization_snapshot.dart';
import 'package:apoorva_app/enum/system_role.dart';

void main() {
  final testDate = DateTime(2026, 3, 30, 10, 0, 0);
  final mockTimestamp = Timestamp.fromDate(testDate);

  group('AppUser Model Tests', () {
    group('Constructor & ID Generation', () {
      test('should generate a valid UUID if no ID is provided', () {
        final user = AppUser(
          name: 'Manikanta',
          email: 'manikanta@apoorva.com',
          createdAt: testDate,
        );

        expect(user.id, isNotEmpty);
        expect(user.id.length, greaterThan(30)); // UUID v4 length check
        expect(user.role, SystemRole.standard); // Default enum
      });

      test('should use provided ID instead of generating one', () {
        final user = AppUser(
          id: 'manual_id_123',
          name: 'Lavanya',
          email: 'lavanya@apoorva.com',
          createdAt: testDate,
        );

        expect(user.id, 'manual_id_123');
      });
    });

    group('Multi-Org Serialization', () {
      test('toJson should handle multiple assigned organizations', () {
        final orgs = [
          OrganizationSnapshot(orgId: 'org_1', name: 'Mangalagiri Main'),
          OrganizationSnapshot(orgId: 'org_2', name: 'Guntur Branch'),
        ];

        final user = AppUser(
          name: 'Admin User',
          email: 'admin@apoorva.com',
          assignedOrgs: orgs,
          createdAt: testDate,
        );

        final json = user.toJson();

        expect(json['assignedOrgs'], isA<List>());
        expect(json['assignedOrgs'].length, 2);
        expect(json['assignedOrgs'][0]['name'], 'Mangalagiri Main');
        expect(json['createdAt'], isA<Timestamp>());
      });

      test(
        'fromJson should reconstruct object with org list and timestamps',
        () {
          final json = {
            'id': 'user_999',
            'name': 'Staff User',
            'email': 'staff@apoorva.com',
            'role': 'standard', // Based on enum string representation
            'status': 'Active',
            'createdAt': mockTimestamp,
            'assignedOrgs': [
              {
                'orgId': 'org_1',
                'name': 'Mangalagiri Main',
                'accentColor': '#FF5733',
              },
            ],
          };

          final user = AppUser.fromJson(json);

          expect(user.id, 'user_999');
          expect(user.assignedOrgs.length, 1);
          expect(user.assignedOrgs.first.name, 'Mangalagiri Main');
          expect(user.createdAt, testDate);
        },
      );
    });

    test('fromJson should default assignedOrgs to empty list if missing', () {
      final json = {
        'name': 'Old User',
        'email': 'old@apoorva.com',
        'createdAt': mockTimestamp,
        // 'assignedOrgs' is missing entirely
      };

      final user = AppUser.fromJson(json);

      expect(user.assignedOrgs, isA<List<OrganizationSnapshot>>());
      expect(user.assignedOrgs, isEmpty);
    });
  });
}
