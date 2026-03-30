import 'package:apoorva_app/model/category/category.dart';

class CartItem {
  final Category category;
  final double stickerPrice; // Price from the manual sticker [cite: 25, 36]
  double discountPercent; // e.g., 5.0 or 10.0
  int quantity;

  CartItem({
    required this.category,
    required this.stickerPrice,
    this.discountPercent = 0.0,
    this.quantity = 1,
  });

  // Smart Calculator Logic: Calculates the final price for this item
  double get finalPrice =>
      (stickerPrice * quantity) * (1 - (discountPercent / 100));
}
