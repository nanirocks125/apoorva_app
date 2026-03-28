import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import '../account.dart'; // Ensure you have the Account model we created

part 'organization.g.dart';

@JsonSerializable(explicitToJson: true)
class Organization {
  String id;
  final String name;
  final String status; // Missing this in your snippet!

  @JsonKey(fromJson: _tsToDate, toJson: _dateToTs)
  final DateTime createdAt;

  final String minVersion;
  final String currentTheme;
  final String accentColor;

  @JsonKey(defaultValue: [])
  final List<Account> accounts; // Missing this in your snippet!

  Organization({
    this.id = '',
    required this.name,
    this.status = "Active",
    required this.createdAt,
    this.minVersion = "1.0.0",
    this.currentTheme = "Default",
    this.accentColor = "#FF5733",
    this.accounts = const [],
  }); // Ensure ID is always initialized, even if empty

  // --- Boilerplate required for build_runner ---
  factory Organization.fromJson(Map<String, dynamic> json) =>
      _$OrganizationFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizationToJson(this);

  // --- Firestore Timestamp Helpers ---
  static DateTime _tsToDate(dynamic ts) => (ts as Timestamp).toDate();
  static dynamic _dateToTs(DateTime dt) => Timestamp.fromDate(dt);
}
