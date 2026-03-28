class SaleItem {
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

  factory SaleItem.fromMap(Map<String, dynamic> data) {
    return SaleItem(
      categoryId: data['cat_id'] ?? '',
      qty: data['qty'] ?? 1,
      stickerPrice: (data['sticker_price'] ?? 0).toDouble(),
      finalPrice: (data['final_price'] ?? 0).toDouble(),
    );
  }
}
