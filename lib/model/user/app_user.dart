import 'package:apoorva_app/enum/system_role.dart';
import 'package:apoorva_app/model/organization/organization_snapshot.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

part 'app_user.g.dart'; // Named app_user to avoid conflict with Firebase 'User'

enum UserRole {
  @JsonValue('owner')
  owner,
  @JsonValue('admin')
  admin,
  @JsonValue('staff')
  staff,
  @JsonValue('manager')
  manager,
}

@JsonSerializable()
class AppUser {
  final String id;
  final String name;
  final String email;
  final SystemRole role;
  final String status;

  // --- The Multi-Org Upgrade ---
  @JsonKey(defaultValue: [])
  final List<OrganizationSnapshot> assignedOrgs;

  @JsonKey(fromJson: _tsToDate, toJson: _dateToTs)
  final DateTime createdAt;

  AppUser({
    String? id,
    required this.name,
    required this.email,
    this.role = SystemRole.standard,
    this.status = 'Active',
    this.assignedOrgs = const [], // Initialize as empty list
    required this.createdAt,
  }) : id = id ?? Uuid().v4();

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
  Map<String, dynamic> toJson() => _$AppUserToJson(this);

  static DateTime _tsToDate(dynamic val) =>
      val is Timestamp ? val.toDate() : DateTime.now();
  static dynamic _dateToTs(DateTime dt) => Timestamp.fromDate(dt);
}
