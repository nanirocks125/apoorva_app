import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:apoorva_app/utilities/timestamp_converter.dart'; // మీ పాత కన్వర్టర్

part 'internal_transfer.g.dart';

@JsonSerializable(explicitToJson: true)
class InternalTransfer {
  @JsonKey(includeToJson: true) // మీరు ID ని JSON లో ఉంచాలనుకున్నారు కాబట్టి
  final String id;

  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final String transferType; // 'type' ని 'transferType' గా మ్యాప్ చేశాను

  @TimestampConverter()
  final DateTime timestamp;

  InternalTransfer({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.transferType,
    required this.timestamp,
  });

  // --- JSON Logic ---
  factory InternalTransfer.fromJson(Map<String, dynamic> json) =>
      _$InternalTransferFromJson(json);

  Map<String, dynamic> toJson() => _$InternalTransferToJson(this);

  // --- Firestore Bridge (ID == DocID) ---
  factory InternalTransfer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InternalTransfer.fromJson(data).copyWithId(doc.id);
  }

  InternalTransfer copyWithId(String newId) => InternalTransfer(
    id: newId,
    fromAccountId: fromAccountId,
    toAccountId: toAccountId,
    amount: amount,
    transferType: transferType,
    timestamp: timestamp,
  );
}
