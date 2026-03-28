import 'package:json_annotation/json_annotation.dart';

part 'organization_snapshot.g.dart'; // <--- YOU ARE MISSING THIS LINE

@JsonSerializable()
class OrganizationSnapshot {
  final String orgId;
  final String name;
  final String accentColor; // So the app theme can change per shop

  OrganizationSnapshot({
    required this.orgId,
    required this.name,
    this.accentColor = "#FF5733",
  });

  factory OrganizationSnapshot.fromJson(Map<String, dynamic> json) =>
      _$OrganizationSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizationSnapshotToJson(this);
}
