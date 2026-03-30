import 'package:apoorva_app/utilities/timestamp_converter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart'; // Ensure this matches your filename

@JsonSerializable()
class Category {
  final String id; // The document ID
  final String name;
  final int currentStock;
  final int billMachineNumber; // Added this field for POS billing

  @TimestampConverter()
  final DateTime? lastSoldDate;
  final bool isHotkey;

  Category({
    required this.id,
    required this.name,
    required this.currentStock,
    this.lastSoldDate,
    required this.isHotkey,
    required this.billMachineNumber, // Ensure this is included in the constructor
  });

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // The Doc ID is the unique integer
    return Category.fromJson(data).copyWithId(doc.id);
  }

  Category copyWithId(String newId) => Category(
    id: newId,
    name: name,
    currentStock: currentStock,
    lastSoldDate: lastSoldDate,
    isHotkey: isHotkey,
    billMachineNumber: billMachineNumber,
  );
}
