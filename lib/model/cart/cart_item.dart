import 'package:apoorva_app/screens/pos/item_price_calculator.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:apoorva_app/model/category/category.dart';

part 'cart_item.g.dart';

@JsonSerializable(explicitToJson: true)
class CartItem {
  final Category category;
  final double stickerPrice;
  final double discountPercent;
  final int quantity;
  final DiscountType discountType;

  CartItem({
    required this.category,
    required this.stickerPrice,
    this.discountPercent = 0.0,
    this.quantity = 1,
    this.discountType = DiscountType.percentage,
  });

  // --- JSON Logic ---
  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);

  Map<String, dynamic> toJson() => _$CartItemToJson(this);

  // --- Logic ---
  double get finalPrice =>
      (stickerPrice * quantity) * (1 - (discountPercent / 100));

  // Bridge method to convert to SaleItem (for Zero Discrepancy)
  // we can use this when confirming the sale.
  /*
  SaleItem toSaleItem() => SaleItem(
    categoryId: category.id,
    qty: quantity,
    stickerPrice: stickerPrice,
    finalPrice: finalPrice,
  );
  */
}
