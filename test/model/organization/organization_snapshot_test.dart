import 'package:apoorva_app/model/organization/organization_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrganizationSnapshot Model Tests', () {
    group('Constructor & Defaults', () {
      test('should initialize with required fields', () {
        final snapshot = OrganizationSnapshot(
          orgId: 'org_123',
          name: 'Apoorva Jewelry',
        );

        expect(snapshot.orgId, 'org_123');
        expect(snapshot.name, 'Apoorva Jewelry');
      });

      test('should use the default accent color if none is provided', () {
        final snapshot = OrganizationSnapshot(
          orgId: 'org_123',
          name: 'Apoorva Jewelry',
        );

        // Verifying the default value set in the constructor
        expect(snapshot.accentColor, '#FF5733');
      });

      test('should use a custom accent color when provided', () {
        final snapshot = OrganizationSnapshot(
          orgId: 'org_456',
          name: 'Apoorva Branch 2',
          accentColor: '#00FF00',
        );

        expect(snapshot.accentColor, '#00FF00');
      });
    });

    group('JSON Serialization', () {
      test('toJson should produce a valid map', () {
        final snapshot = OrganizationSnapshot(
          orgId: 'org_789',
          name: 'Mangalagiri Main',
          accentColor: '#B8860B', // Dark Goldenrod
        );

        final json = snapshot.toJson();

        expect(json['orgId'], 'org_789');
        expect(json['name'], 'Mangalagiri Main');
        expect(json['accentColor'], '#B8860B');
      });

      test('fromJson should create a valid object', () {
        final json = {
          'orgId': 'org_001',
          'name': 'Apoorva One-Gram',
          'accentColor': '#FFD700',
        };

        final snapshot = OrganizationSnapshot.fromJson(json);

        expect(snapshot.orgId, 'org_001');
        expect(snapshot.name, 'Apoorva One-Gram');
        expect(snapshot.accentColor, '#FFD700');
      });

      test(
        'fromJson should apply default values for missing optional fields',
        () {
          final json = {
            'orgId': 'org_002',
            'name': 'Apoorva Boutique',
            // accentColor is missing in the JSON
          };

          final snapshot = OrganizationSnapshot.fromJson(json);

          expect(snapshot.accentColor, '#FF5733'); // Default from model
        },
      );
    });
  });
}
