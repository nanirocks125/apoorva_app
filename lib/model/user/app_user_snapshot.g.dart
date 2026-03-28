// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUserSnapshot _$AppUserSnapshotFromJson(Map<String, dynamic> json) =>
    AppUserSnapshot(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      orgRole: json['orgRole'] as String? ?? 'staff',
    );

Map<String, dynamic> _$AppUserSnapshotToJson(AppUserSnapshot instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'name': instance.name,
      'email': instance.email,
      'orgRole': instance.orgRole,
    };
