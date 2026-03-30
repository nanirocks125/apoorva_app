import 'package:json_annotation/json_annotation.dart';

enum AppUserRole {
  @JsonValue('super_admin')
  superAdmin, // You: Full platform control
  @JsonValue('support')
  support, // Tech support: Can see data but not edit settings
  @JsonValue('standard')
  standard, // Everyone else: No global powers
}
