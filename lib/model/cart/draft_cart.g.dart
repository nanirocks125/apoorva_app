// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_cart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DraftCart _$DraftCartFromJson(Map<String, dynamic> json) => DraftCart(
  id: json['id'] as String,
  customerName: json['customerName'] as String,
  customerPhone: json['customerPhone'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$DraftCartToJson(DraftCart instance) => <String, dynamic>{
  'id': instance.id,
  'customerName': instance.customerName,
  'customerPhone': instance.customerPhone,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'total': instance.total,
  'createdAt': instance.createdAt.toIso8601String(),
};
