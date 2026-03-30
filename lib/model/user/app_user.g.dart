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
      $enumDecodeNullable(_$AppUserRoleEnumMap, json['role']) ??
      AppUserRole.standard,
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
  'role': _$AppUserRoleEnumMap[instance.role]!,
  'status': instance.status,
  'assignedOrgs': instance.assignedOrgs.map((e) => e.toJson()).toList(),
  'createdAt': AppUser._dateToTs(instance.createdAt),
};

const _$AppUserRoleEnumMap = {
  AppUserRole.superAdmin: 'super_admin',
  AppUserRole.support: 'support',
  AppUserRole.standard: 'standard',
};
