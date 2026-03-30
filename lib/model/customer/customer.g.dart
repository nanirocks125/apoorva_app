// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Customer _$CustomerFromJson(Map<String, dynamic> json) => Customer(
  name: json['name'] as String,
  phone: json['phone'] as String,
  createdAt: Customer._dateTimeFromTimestamp(json['created_at']),
  visitCount: (json['visitCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CustomerToJson(Customer instance) => <String, dynamic>{
  'name': instance.name,
  'phone': instance.phone,
  'created_at': Customer._dateTimeToTimestamp(instance.createdAt),
  'visitCount': instance.visitCount,
};
