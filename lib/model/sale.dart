import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:apoorva_app/model/sale_item.dart'; // Ensure SaleItem is also serialized
import 'package:apoorva_app/utilities/timestamp_converter.dart';

part 'sale.g.dart';

@JsonSerializable(explicitToJson: true)
class Sale {
  @JsonKey(includeToJson: true)
  final String id;

  @TimestampConverter()
  final DateTime timestamp;

  final String staffId;
  final String customerPhone;
  final List<SaleItem> items;

  // { "cash": 1000.0, "upi": 500.0 }
  final Map<String, double> tenderDetails;

  final double totalAmount;
  final String source; // Instagram, WhatsApp, Walk-in
  final String status; // Completed, Voided

  Sale({
    required this.id,
    required this.timestamp,
    required this.staffId,
    required this.customerPhone,
    required this.items,
    required this.tenderDetails,
    required this.totalAmount,
    required this.source,
    required this.status,
  });

  // --- JSON Logic ---
  factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);

  Map<String, dynamic> toJson() => _$SaleToJson(this);

  // --- Firestore Bridge (ID == DocID) ---
  factory Sale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sale.fromJson(data).copyWithId(doc.id);
  }

  Sale copyWithId(String newId) => Sale(
    id: newId,
    timestamp: timestamp,
    staffId: staffId,
    customerPhone: customerPhone,
    items: items,
    tenderDetails: tenderDetails,
    totalAmount: totalAmount,
    source: source,
    status: status,
  );
}
