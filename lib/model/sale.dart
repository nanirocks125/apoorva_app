import 'package:apoorva_app/enum/payment_mode.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:apoorva_app/model/sale_item.dart';
import 'package:apoorva_app/utilities/timestamp_converter.dart';

part 'sale.g.dart';

@JsonSerializable(explicitToJson: true)
class Sale {
  final String id;

  final String staffId;
  final String customerPhone;
  final String customerName; // Added for searchability
  final List<SaleItem> items;

  // --- Financial Details (Crucial for Jewelry Retail) ---
  final double subtotal;
  final double overallDiscountPercent;
  final double overallDiscountAmount;
  final double roundOff;
  final double netPayable; // Final amount the customer pays

  // String బదులు Enum వాడితే బగ్స్ రావు
  final Map<PaymentMode, double> payments;

  @TimestampConverter()
  final DateTime timestamp;

  final String source; // Instagram, WhatsApp, Walk-in
  final String status; // Completed, Voided
  final String whatsappStatus; // 'unsent', 'sent'

  Sale({
    required this.id,
    required this.staffId,
    required this.customerPhone,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.overallDiscountPercent,
    required this.overallDiscountAmount,
    required this.roundOff,
    required this.netPayable,
    required this.payments,
    required this.timestamp,
    required this.source,
    required this.status,
    this.whatsappStatus = 'unsent',
  });

  factory Sale.fromJson(Map<String, dynamic> json) => _$SaleFromJson(json);
  Map<String, dynamic> toJson() => _$SaleToJson(this);

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Sale.fromJson(data).copyWithId(doc.id);
  }

  Sale copyWithId(String newId) => Sale(
    id: newId,
    staffId: staffId,
    customerPhone: customerPhone,
    customerName: customerName,
    items: items,
    subtotal: subtotal,
    overallDiscountPercent: overallDiscountPercent,
    overallDiscountAmount: overallDiscountAmount,
    roundOff: roundOff,
    netPayable: netPayable,
    payments: payments,
    timestamp: timestamp,
    source: source,
    status: status,
    whatsappStatus: whatsappStatus,
  );
}
