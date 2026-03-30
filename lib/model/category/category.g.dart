// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: json['id'] as String,
  name: json['name'] as String,
  currentStock: (json['currentStock'] as num).toInt(),
  lastSoldDate: const TimestampConverter().fromJson(json['lastSoldDate']),
  isHotkey: json['isHotkey'] as bool,
  billMachineNumber: (json['billMachineNumber'] as num).toInt(),
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'currentStock': instance.currentStock,
  'billMachineNumber': instance.billMachineNumber,
  'lastSoldDate': _$JsonConverterToJson<dynamic, DateTime>(
    instance.lastSoldDate,
    const TimestampConverter().toJson,
  ),
  'isHotkey': instance.isHotkey,
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
