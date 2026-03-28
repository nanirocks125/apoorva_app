// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Organization _$OrganizationFromJson(Map<String, dynamic> json) => Organization(
  id: json['id'] as String? ?? '',
  name: json['name'] as String,
  status: json['status'] as String? ?? "Active",
  createdAt: Organization._tsToDate(json['createdAt']),
  minVersion: json['minVersion'] as String? ?? "1.0.0",
  currentTheme: json['currentTheme'] as String? ?? "Default",
  accentColor: json['accentColor'] as String? ?? "#FF5733",
  accounts:
      (json['accounts'] as List<dynamic>?)
          ?.map((e) => Account.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$OrganizationToJson(Organization instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': instance.status,
      'createdAt': Organization._dateToTs(instance.createdAt),
      'minVersion': instance.minVersion,
      'currentTheme': instance.currentTheme,
      'accentColor': instance.accentColor,
      'accounts': instance.accounts.map((e) => e.toJson()).toList(),
    };
