import 'package:apoorva_app/model/internal_transfer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  final testDate = DateTime(2026, 3, 30, 23, 45, 0);
  final mockTimestamp = Timestamp.fromDate(testDate);

  group('InternalTransfer Model Tests', () {
    test('Constructor should initialize all fields correctly', () {
      final transfer = InternalTransfer(
        id: 'trans_001',
        fromAccountId: 'cash_drawer',
        toAccountId: 'hdfc_bank',
        amount: 5000.0,
        transferType: 'Cash Deposit',
        timestamp: testDate,
      );

      expect(transfer.id, 'trans_001');
      expect(transfer.amount, 5000.0);
      expect(transfer.fromAccountId, 'cash_drawer');
      expect(transfer.timestamp, testDate);
    });

    test('copyWithId should return a new instance with the updated ID', () {
      final transfer = InternalTransfer(
        id: 'old_id',
        fromAccountId: 'acc_1',
        toAccountId: 'acc_2',
        amount: 100.0,
        transferType: 'test',
        timestamp: testDate,
      );

      final updatedTransfer = transfer.copyWithId('new_id_999');

      expect(updatedTransfer.id, 'new_id_999');
      expect(updatedTransfer.amount, 100.0); // Remains the same
      expect(identical(transfer, updatedTransfer), isFalse);
    });

    group('JSON Serialization', () {
      test('toJson should convert DateTime to Firestore Timestamp', () {
        final transfer = InternalTransfer(
          id: 'trans_123',
          fromAccountId: 'wallet',
          toAccountId: 'bank',
          amount: 250.0,
          transferType: 'Digital to Bank',
          timestamp: testDate,
        );

        final json = transfer.toJson();

        expect(json['id'], 'trans_123');
        expect(json['amount'], 250.0);
        // Checking the TimestampConverter logic
        expect(json['timestamp'], isA<Timestamp>());
        expect(json['timestamp'], mockTimestamp);
      });

      test('fromJson should handle Firestore Timestamps correctly', () {
        final json = {
          'id': 'json_trans_456',
          'fromAccountId': 'cash',
          'toAccountId': 'bank',
          'amount': 1000.0,
          'transferType': 'Deposit',
          'timestamp': mockTimestamp, // Simulated Firestore data
        };

        final transfer = InternalTransfer.fromJson(json);

        expect(transfer.id, 'json_trans_456');
        expect(transfer.amount, 1000.0);
        expect(transfer.timestamp, testDate);
        expect(transfer.transferType, 'Deposit');
      });
    });
  });
}
