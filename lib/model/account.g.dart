// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
  id: json['id'] as String?,
  name: json['name'] as String,
  type: $enumDecode(_$AccountTypeEnumMap, json['type']),
  currentBalance: (json['currentBalance'] as num).toDouble(),
);

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': _$AccountTypeEnumMap[instance.type]!,
  'currentBalance': instance.currentBalance,
};

const _$AccountTypeEnumMap = {
  AccountType.cash: 'cash',
  AccountType.bank: 'bank',
  AccountType.upi: 'upi',
};
