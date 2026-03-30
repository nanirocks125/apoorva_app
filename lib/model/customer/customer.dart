import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'customer.g.dart';

@JsonSerializable(explicitToJson: true)
class Customer {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id; // Document ID from Firestore

  final String name;
  final String phone;

  @JsonKey(
    name: 'created_at',
    fromJson: _dateTimeFromTimestamp,
    toJson: _dateTimeToTimestamp,
  )
  final DateTime createdAt;

  @JsonKey(defaultValue: 0)
  final int visitCount;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
    this.visitCount = 0,
  });

  // --- JSON SERIALIZATION ---
  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerToJson(this);

  // --- FIRESTORE HELPERS ---
  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer.fromJson(data).copyWithId(doc.id);
  }

  // Helper to keep the model immutable while adding the Firestore ID
  Customer copyWithId(String id) {
    return Customer(
      id: id,
      name: name,
      phone: phone,
      createdAt: createdAt,
      visitCount: visitCount,
    );
  }

  // Custom converters for Firestore Timestamps
  static DateTime _dateTimeFromTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    return DateTime.now();
  }

  static dynamic _dateTimeToTimestamp(DateTime dateTime) =>
      Timestamp.fromDate(dateTime);
}
