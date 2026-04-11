import 'package:apoorva_app/enum/discount_type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:apoorva_app/model/category/category.dart';

part 'cart_item.g.dart';

@JsonSerializable(explicitToJson: true)
class CartItem {
  final Category category;
  final double mrp;
  final double discountPercent;
  final int quantity;
  final DiscountType discountType;

  CartItem({
    required this.category,
    required this.mrp,
    this.discountPercent = 0.0,
    required this.quantity,
    this.discountType = DiscountType.percentage,
  });

  // --- JSON Logic ---
  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);

  Map<String, dynamic> toJson() => _$CartItemToJson(this);

  // --- Logic ---
  double get finalPrice => (mrp) * (1 - (discountPercent / 100));

  double get totalItemsPrice => quantity * finalPrice;

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
