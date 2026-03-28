// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrganizationSnapshot _$OrganizationSnapshotFromJson(
  Map<String, dynamic> json,
) => OrganizationSnapshot(
  orgId: json['orgId'] as String,
  name: json['name'] as String,
  accentColor: json['accentColor'] as String? ?? "#FF5733",
);

Map<String, dynamic> _$OrganizationSnapshotToJson(
  OrganizationSnapshot instance,
) => <String, dynamic>{
  'orgId': instance.orgId,
  'name': instance.name,
  'accentColor': instance.accentColor,
};
