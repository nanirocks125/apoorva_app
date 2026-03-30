import 'package:apoorva_app/model/account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/enum/account_type.dart';

void main() {
  group('Account Model Tests', () {
    group('Constructor & ID Generation', () {
      test('should generate a unique UUID if no ID is provided', () {
        final account = Account(
          name: 'Main Cash Drawer',
          type: AccountType.cash,
          currentBalance: 5000.0,
        );

        expect(account.id, isNotEmpty);
        // UUID v4 is 36 characters long (including hyphens)
        expect(account.id.length, 36);
      });

      test('should use the provided ID instead of generating one', () {
        final manualId = 'acc_mangalagiri_01';
        final account = Account(
          id: manualId,
          name: 'HDFC Bank',
          type: AccountType.bank,
          currentBalance: 125000.0,
        );

        expect(account.id, manualId);
      });
    });

    group('JSON Serialization', () {
      test('toJson should convert the object into a valid Map', () {
        final account = Account(
          id: 'test_id_123',
          name: 'PhonePe Wallet',
          type: AccountType.cash,
          currentBalance: 450.75,
        );

        final json = account.toJson();

        expect(json['id'], 'test_id_123');
        expect(json['name'], 'PhonePe Wallet');
        expect(json['currentBalance'], 450.75);
        // Verify enum string representation (assuming default json_serializable behavior)
        expect(json['type'], 'cash');
      });

      test('fromJson should correctly recreate the object from a Map', () {
        final json = {
          'id': 'json_id_999',
          'name': 'Counter Cash',
          'type': 'cash',
          'currentBalance': 1000.0,
        };

        final account = Account.fromJson(json);

        expect(account.id, 'json_id_999');
        expect(account.name, 'Counter Cash');
        expect(account.type, AccountType.cash);
        expect(account.currentBalance, 1000.0);
      });
    });
  });
}
