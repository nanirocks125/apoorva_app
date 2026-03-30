import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:apoorva_app/utilities/timestamp_converter.dart';

part 'draft_cart.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class DraftCart {
  final String id;
  final String customerName;
  final String customerPhone;
  final List<CartItem> items;
  final double total;

  @TimestampConverter()
  final DateTime createdAt;

  DraftCart({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.total,
    required this.createdAt,
  });

  factory DraftCart.fromJson(Map<String, dynamic> json) =>
      _$DraftCartFromJson(json);
  Map<String, dynamic> toJson() => _$DraftCartToJson(this);

  factory DraftCart.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DraftCart.fromJson(data).copyWithId(doc.id);
  }

  DraftCart copyWithId(String newId) => DraftCart(
    id: newId,
    customerName: customerName,
    customerPhone: customerPhone,
    items: items,
    total: total,
    createdAt: createdAt,
  );
}
