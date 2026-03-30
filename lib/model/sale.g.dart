// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sale _$SaleFromJson(Map<String, dynamic> json) => Sale(
  id: json['id'] as String,
  staffId: json['staff_id'] as String,
  customerPhone: json['customer_phone'] as String,
  customerName: json['customer_name'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  subtotal: (json['subtotal'] as num).toDouble(),
  overallDiscountPercent: (json['overall_discount_percent'] as num).toDouble(),
  overallDiscountAmount: (json['overall_discount_amount'] as num).toDouble(),
  roundOff: (json['round_off'] as num).toDouble(),
  netPayable: (json['net_payable'] as num).toDouble(),
  payments: (json['payments'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry($enumDecode(_$PaymentModeEnumMap, k), (e as num).toDouble()),
  ),
  timestamp: DateTime.parse(json['timestamp'] as String),
  source: json['source'] as String,
  status: json['status'] as String,
  whatsappStatus: json['whatsapp_status'] as String? ?? 'unsent',
);

Map<String, dynamic> _$SaleToJson(Sale instance) => <String, dynamic>{
  'id': instance.id,
  'staff_id': instance.staffId,
  'customer_phone': instance.customerPhone,
  'customer_name': instance.customerName,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'subtotal': instance.subtotal,
  'overall_discount_percent': instance.overallDiscountPercent,
  'overall_discount_amount': instance.overallDiscountAmount,
  'round_off': instance.roundOff,
  'net_payable': instance.netPayable,
  'payments': instance.payments.map(
    (k, e) => MapEntry(_$PaymentModeEnumMap[k]!, e),
  ),
  'timestamp': instance.timestamp.toIso8601String(),
  'source': instance.source,
  'status': instance.status,
  'whatsapp_status': instance.whatsappStatus,
};

const _$PaymentModeEnumMap = {
  PaymentMode.cash: 'cash',
  PaymentMode.upi: 'upi',
  PaymentMode.card: 'card',
  PaymentMode.credit: 'credit',
};
