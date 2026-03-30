import 'package:json_annotation/json_annotation.dart';

part 'sale_item.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class SaleItem {
  // Keeping 'cat_id' for backwards compatibility with your existing data
  @JsonKey(name: 'cat_id')
  final String categoryId;

  final int qty;
  final double stickerPrice;
  final double finalPrice;

  SaleItem({
    required this.categoryId,
    required this.qty,
    required this.stickerPrice,
    required this.finalPrice,
  });

  // --- JSON Logic ---
  factory SaleItem.fromJson(Map<String, dynamic> json) =>
      _$SaleItemFromJson(json);

  Map<String, dynamic> toJson() => _$SaleItemToJson(this);
}
