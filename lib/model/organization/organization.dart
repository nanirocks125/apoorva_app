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

  Organization copyWith({
    String? id,
    String? name,
    String? status,
    DateTime? createdAt,
    bool setCreatedAtToNull = false, // Helper to explicitly set null
    String? minVersion,
    String? currentTheme,
    String? accentColor,
    List<Account>? accounts,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      minVersion: minVersion ?? this.minVersion,
      currentTheme: currentTheme ?? this.currentTheme,
      accentColor: accentColor ?? this.accentColor,
      accounts: accounts ?? this.accounts,
    );
  }

  // --- Boilerplate required for build_runner ---
  factory Organization.fromJson(Map<String, dynamic> json) =>
      _$OrganizationFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizationToJson(this);

  // --- Firestore Timestamp Helpers ---
  static DateTime _tsToDate(dynamic ts) => (ts as Timestamp).toDate();
  static dynamic _dateToTs(DateTime dt) => Timestamp.fromDate(dt);
}
