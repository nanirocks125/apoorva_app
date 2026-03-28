import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final int currentStock;
  final DateTime? lastSoldDate;
  final bool isHotkey;
  final String? socialMediaLink;

  Category({
    required this.id,
    required this.name,
    required this.currentStock,
    this.lastSoldDate,
    required this.isHotkey,
    this.socialMediaLink,
  });

  factory Category.fromMap(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      name: data['name'] ?? '',
      currentStock: data['current_stock'] ?? 0,
      lastSoldDate: (data['last_sold_date'] as Timestamp?)?.toDate(),
      isHotkey: data['is_hotkey'] ?? false,
      socialMediaLink: data['social_media_link'],
    );
  }
}
