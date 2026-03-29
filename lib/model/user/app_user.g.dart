// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUser _$AppUserFromJson(Map<String, dynamic> json) => AppUser(
  id: json['id'] as String?,
  name: json['name'] as String,
  email: json['email'] as String,
  role:
      $enumDecodeNullable(_$SystemRoleEnumMap, json['role']) ??
      SystemRole.standard,
  status: json['status'] as String? ?? 'Active',
  assignedOrgs:
      (json['assignedOrgs'] as List<dynamic>?)
          ?.map((e) => OrganizationSnapshot.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  createdAt: AppUser._tsToDate(json['createdAt']),
);

Map<String, dynamic> _$AppUserToJson(AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'role': _$SystemRoleEnumMap[instance.role]!,
  'status': instance.status,
  'assignedOrgs': instance.assignedOrgs,
  'createdAt': AppUser._dateToTs(instance.createdAt),
};

const _$SystemRoleEnumMap = {
  SystemRole.superAdmin: 'super_admin',
  SystemRole.support: 'support',
  SystemRole.standard: 'standard',
};
