import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/enum/payment_mode.dart';

void main() {
  group('PaymentMode Enum Tests', () {
    test('should have all 4 payment modes defined', () {
      expect(PaymentMode.values.length, 4);
      expect(PaymentMode.values, contains(PaymentMode.cash));
      expect(PaymentMode.values, contains(PaymentMode.upi));
      expect(PaymentMode.values, contains(PaymentMode.card));
      expect(PaymentMode.values, contains(PaymentMode.credit));
    });

    group('UI Helper: displayName', () {
      test('should return correct user-facing strings', () {
        expect(PaymentMode.cash.displayName, 'Cash');
        expect(PaymentMode.upi.displayName, 'UPI / PhonePe');
        expect(PaymentMode.card.displayName, 'Card');
        expect(PaymentMode.credit.displayName, 'Store Credit');
      });
    });

    group('UI Helper: icon', () {
      test('should return specific Icons for each mode', () {
        expect(PaymentMode.cash.icon, Icons.payments_outlined);
        expect(PaymentMode.upi.icon, Icons.qr_code_scanner_outlined);
        expect(PaymentMode.card.icon, Icons.credit_card_outlined);
        expect(PaymentMode.credit.icon, Icons.person_outline);
      });
    });

    group('JSON Serialization Mapping', () {
      test('internal names should be lowercase for Firestore', () {
        // This ensures your @JsonValue matches the expected database contract
        expect(PaymentMode.cash.name, 'cash');
        expect(PaymentMode.upi.name, 'upi');
        expect(PaymentMode.card.name, 'card');
        expect(PaymentMode.credit.name, 'credit');
      });
    });
  });
}
