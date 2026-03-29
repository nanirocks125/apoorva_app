// Individual Item in the Cart
class CartItem {
  final String categoryId;
  final String categoryName;
  final double stickerPrice; // Price from the manual sticker [cite: 25, 36]
  double discountPercent; // e.g., 5.0 or 10.0
  int quantity;

  CartItem({
    required this.categoryId,
    required this.categoryName,
    required this.stickerPrice,
    this.discountPercent = 0.0,
    this.quantity = 1,
  });

  // Smart Calculator Logic: Calculates the final price for this item
  double get finalPrice =>
      (stickerPrice * quantity) * (1 - (discountPercent / 100));
}
