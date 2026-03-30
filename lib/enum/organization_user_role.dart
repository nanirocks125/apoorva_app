import 'package:json_annotation/json_annotation.dart';

enum OrganizationUserRole {
  @JsonValue('owner')
  owner,
  @JsonValue('admin')
  admin,
  @JsonValue('staff')
  staff,
  @JsonValue('manager')
  manager,
}
