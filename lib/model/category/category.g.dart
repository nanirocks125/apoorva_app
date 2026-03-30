// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: json['id'] as String,
  name: json['name'] as String,
  currentStock: (json['current_stock'] as num).toInt(),
  lastSoldDate: Category._dateTimeFromTimestamp(json['last_sold_date']),
  isHotkey: json['is_hotkey'] as bool,
  socialMediaLink: json['social_media_link'] as String?,
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'current_stock': instance.currentStock,
  'last_sold_date': Category._dateTimeToTimestamp(instance.lastSoldDate),
  'is_hotkey': instance.isHotkey,
  'social_media_link': instance.socialMediaLink,
};
