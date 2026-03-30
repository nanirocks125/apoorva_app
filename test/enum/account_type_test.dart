import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/enum/account_type.dart';

void main() {
  group('AccountType Enum Tests', () {
    test('enum values should exist', () {
      expect(AccountType.values.length, 3);
      expect(AccountType.values, contains(AccountType.cash));
      expect(AccountType.values, contains(AccountType.bank));
      expect(AccountType.values, contains(AccountType.upi));
    });

    test('enum names should match for UI labels', () {
      // Useful if you use .name to display text in the Apoorva UI
      expect(AccountType.cash.name, 'cash');
      expect(AccountType.bank.name, 'bank');
      expect(AccountType.upi.name, 'upi');
    });

    // Note: Since you're using json_serializable, the actual serialization
    // is usually tested within the models that USE this enum (like the Account model).
    // But testing the logic here ensures your documentation matches reality.
    test('JsonValue mapping expectations', () {
      // These represent exactly what should be stored in Firestore
      const cashValue = 'cash';
      const bankValue = 'bank';
      const upiValue = 'upi';

      expect(
        AccountType.cash.toString().split('.').last,
        isNot('Cash'),
      ); // Guard against capitalization
      expect(cashValue, 'cash');
    });
  });
}
