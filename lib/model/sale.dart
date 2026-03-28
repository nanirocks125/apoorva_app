import 'package:apoorva_app/model/sale_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Sale {
  final String id;
  final DateTime timestamp;
  final String staffId;
  final String customerPhone;
  final List<SaleItem> items;
  final Map<String, double> tenderDetails; // { "cash": 1000, "upi": 500 }
  final double totalAmount;
  final String source; // Instagram, WhatsApp, etc.
  final String status; // Completed or Voided

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

  factory Sale.fromMap(Map<String, dynamic> data, String id) {
    var itemsList = (data['items'] as List)
        .map((item) => SaleItem.fromMap(item))
        .toList();

    return Sale(
      id: id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      staffId: data['staff_id'] ?? '',
      customerPhone: data['customer_phone'] ?? '',
      items: itemsList,
      tenderDetails: Map<String, double>.from(data['tender_details'] ?? {}),
      totalAmount: (data['total_amount'] ?? 0).toDouble(),
      source: data['source'] ?? 'Walk-in',
      status: data['status'] ?? 'Completed',
    );
  }
}
