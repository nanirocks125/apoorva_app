// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sale _$SaleFromJson(Map<String, dynamic> json) => Sale(
  id: json['id'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  staffId: json['staffId'] as String,
  customerPhone: json['customerPhone'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  tenderDetails: (json['tenderDetails'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  source: json['source'] as String,
  status: json['status'] as String,
);

Map<String, dynamic> _$SaleToJson(Sale instance) => <String, dynamic>{
  'id': instance.id,
  'timestamp': instance.timestamp.toIso8601String(),
  'staffId': instance.staffId,
  'customerPhone': instance.customerPhone,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'tenderDetails': instance.tenderDetails,
  'totalAmount': instance.totalAmount,
  'source': instance.source,
  'status': instance.status,
};
