// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sale _$SaleFromJson(Map<String, dynamic> json) => Sale(
  id: json['id'] as String,
  staffId: json['staffId'] as String,
  customerPhone: json['customerPhone'] as String,
  customerName: json['customerName'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  subtotal: (json['subtotal'] as num).toDouble(),
  overallDiscountPercent: (json['overallDiscountPercent'] as num).toDouble(),
  overallDiscountAmount: (json['overallDiscountAmount'] as num).toDouble(),
  roundOff: (json['roundOff'] as num).toDouble(),
  netPayable: (json['netPayable'] as num).toDouble(),
  payments: (json['payments'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry($enumDecode(_$PaymentModeEnumMap, k), (e as num).toDouble()),
  ),
  timestamp: const TimestampConverter().fromJson(json['timestamp']),
  source: json['source'] as String,
  status: json['status'] as String,
  whatsappStatus: json['whatsappStatus'] as String? ?? 'unsent',
);

Map<String, dynamic> _$SaleToJson(Sale instance) => <String, dynamic>{
  'id': instance.id,
  'staffId': instance.staffId,
  'customerPhone': instance.customerPhone,
  'customerName': instance.customerName,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'subtotal': instance.subtotal,
  'overallDiscountPercent': instance.overallDiscountPercent,
  'overallDiscountAmount': instance.overallDiscountAmount,
  'roundOff': instance.roundOff,
  'netPayable': instance.netPayable,
  'payments': instance.payments.map(
    (k, e) => MapEntry(_$PaymentModeEnumMap[k]!, e),
  ),
  'timestamp': const TimestampConverter().toJson(instance.timestamp),
  'source': instance.source,
  'status': instance.status,
  'whatsappStatus': instance.whatsappStatus,
};

const _$PaymentModeEnumMap = {
  PaymentMode.cash: 'cash',
  PaymentMode.upi: 'upi',
  PaymentMode.card: 'card',
  PaymentMode.credit: 'credit',
};
