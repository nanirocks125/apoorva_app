import 'package:cloud_firestore/cloud_firestore.dart';

class InternalTransfer {
  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final String type; // Bank Deposit, Petty Cash Refill
  final DateTime timestamp;

  InternalTransfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount': amount,
      'transfer_type': type,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
