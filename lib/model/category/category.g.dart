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
  'lastSoldDate': const TimestampConverter().toJson(instance.lastSoldDate),
  'isHotkey': instance.isHotkey,
};
