import 'package:json_annotation/json_annotation.dart';

part 'app_user_snapshot.g.dart'; // <--- YOU ARE MISSING THIS LINE

@JsonSerializable()
class AppUserSnapshot {
  final String uid;
  final String name;
  final String email;
  final String orgRole; // e.g., 'manager', 'sales_staff'

  AppUserSnapshot({
    required this.uid,
    required this.name,
    required this.email,
    this.orgRole = 'staff',
  });

  factory AppUserSnapshot.fromJson(Map<String, dynamic> json) =>
      _$AppUserSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$AppUserSnapshotToJson(this);
}
