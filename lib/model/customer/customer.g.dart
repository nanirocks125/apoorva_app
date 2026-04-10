// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
  name: json['name'] as String,
  phone: json['phone'] as String,
  lastPurchaseDate: const NullableTimestampConverter().fromJson(
    json['lastPurchaseDate'],
  ),
  totalSales: (json['totalSales'] as num?)?.toInt() ?? 0,
  totalAmountSpent: (json['totalAmountSpent'] as num?)?.toDouble() ?? 0,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
  'name': instance.name,
  'phone': instance.phone,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'lastPurchaseDate': const NullableTimestampConverter().toJson(
    instance.lastPurchaseDate,
  ),
  'totalSales': instance.totalSales,
  'totalAmountSpent': instance.totalAmountSpent,
};
