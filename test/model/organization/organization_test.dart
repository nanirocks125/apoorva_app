import 'package:apoorva_app/enum/account_type.dart';
import 'package:apoorva_app/model/account.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  final testDate = DateTime(2026, 3, 30, 10, 0, 0);
  final mockTimestamp = Timestamp.fromDate(testDate);

  group('Organization Model Tests', () {
    test('Constructor should initialize with correct defaults', () {
      final org = Organization(name: 'Apoorva Jewelry', createdAt: testDate);

      expect(org.name, 'Apoorva Jewelry');
      expect(org.status, 'Active'); // Default
      expect(org.minVersion, '1.0.0'); // Default
      expect(org.accentColor, '#FF5733'); // Default
      expect(org.accounts, isEmpty); // Default
      expect(org.id, ''); // Initialized as empty string
    });

    group('JSON Serialization (toJson)', () {
      test('should convert DateTime to Firestore Timestamp', () {
        final org = Organization(
          name: 'Mangalagiri Branch',
          createdAt: testDate,
          accounts: [
            Account(
              id: 'acc_1',
              name: 'Lavanya',
              type: AccountType.cash,
              currentBalance: 0,
            ),
          ],
        );

        final json = org.toJson();

        expect(json['name'], 'Mangalagiri Branch');
        expect(json['createdAt'], isA<Timestamp>());
        expect(json['createdAt'], mockTimestamp);

        // explicitToJson: true check
        expect(json['accounts'][0], isA<Map<String, dynamic>>());
        expect(json['accounts'][0]['name'], 'Lavanya');
      });
    });

    group('JSON Deserialization (fromJson)', () {
      test(
        'should handle Timestamp conversion and missing optional fields',
        () {
          final json = {
            'name': 'Apoorva POS',
            'createdAt': mockTimestamp,
            'status': 'Maintenance',
            // accounts, minVersion, accentColor are missing
          };

          final org = Organization.fromJson(json);

          expect(org.name, 'Apoorva POS');
          expect(org.createdAt, testDate);
          expect(org.status, 'Maintenance');

          // Check defaults for missing keys
          expect(org.minVersion, '1.0.0');
          expect(org.accentColor, '#FF5733');
          expect(org.accounts, isA<List<Account>>());
          expect(org.accounts, isEmpty);
        },
      );

      test('should correctly deserialize a full account list', () {
        final json = {
          'name': 'Main Hub',
          'createdAt': mockTimestamp,
          'accounts': [
            {
              'id': 'staff_1',
              'name': 'Manikanta',
              'type': 'cash',
              'currentBalance': 0.0,
            },
            {
              'id': 'staff_2',
              'name': 'Staff Member',
              'type': 'bank',
              'currentBalance': 0.0,
            },
          ],
        };

        final org = Organization.fromJson(json);

        expect(org.accounts.length, 2);
        expect(org.accounts[0].name, 'Manikanta');
        expect(org.accounts[1].type, AccountType.bank);
      });
    });
  });
}
