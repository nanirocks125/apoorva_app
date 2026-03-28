import 'package:cloud_firestore/cloud_firestore.dart';

class Organization {
  final String id;
  final String name;
  final DateTime createdAt;
  final String minVersion; // For Forced Update Toggle
  final String currentTheme; // For Seasonal UI
  final String accentColor;

  Organization({
    required this.id,
    required this.name,
    required this.createdAt,
    this.minVersion = "1.0.0",
    this.currentTheme = "Default",
    this.accentColor = "#FF5733",
  });

  factory Organization.fromMap(Map<String, dynamic> data, String id) {
    return Organization(
      id: id,
      name: data['org_name'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      minVersion: data['config']?['system']?['min_version'] ?? "1.0.0",
      currentTheme: data['config']?['ui_theme']?['current_theme'] ?? "Default",
      accentColor: data['config']?['ui_theme']?['accent_color'] ?? "#FF5733",
    );
  }
}
