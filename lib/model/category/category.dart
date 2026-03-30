import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart'; // Ensure this matches your filename

@JsonSerializable(explicitToJson: true)
class Category {
  final String id;

  final String name;

  @JsonKey(name: 'current_stock')
  final int currentStock;

  @JsonKey(
    name: 'last_sold_date',
    fromJson: _dateTimeFromTimestamp,
    toJson: _dateTimeToTimestamp,
  )
  final DateTime? lastSoldDate;

  @JsonKey(name: 'is_hotkey')
  final bool isHotkey;

  @JsonKey(name: 'social_media_link')
  final String? socialMediaLink;

  Category({
    required this.id,
    required this.name,
    required this.currentStock,
    this.lastSoldDate,
    required this.isHotkey,
    this.socialMediaLink,
  });

  // --- JSON Logic ---
  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  // --- Firestore Helper ---
  // This bridges the gap between the DocumentSnapshot and your Model
  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category.fromJson(data).copyWithId(doc.id);
  }

  // Helper to attach the Firestore ID to the model
  Category copyWithId(String docId) {
    return Category(
      id: docId,
      name: name,
      currentStock: currentStock,
      lastSoldDate: lastSoldDate,
      isHotkey: isHotkey,
      socialMediaLink: socialMediaLink,
    );
  }

  // --- Custom Converters for Firestore Timestamps ---
  static DateTime? _dateTimeFromTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }

  static dynamic _dateTimeToTimestamp(DateTime? dateTime) {
    return dateTime != null ? Timestamp.fromDate(dateTime) : null;
  }
}
