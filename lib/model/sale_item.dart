import 'package:apoorva_app/enum/discount_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sale_item.g.dart';

@JsonSerializable(explicitToJson: true)
class SaleItem {
  // Keeping 'cat_id' for backwards compatibility with your existing data
  @JsonKey(name: 'cat_id')
  final String categoryId;

  @JsonKey(defaultValue: '')
  final String categoryName;

  @JsonKey(defaultValue: 0)
  final int qty;
  @JsonKey(defaultValue: 0)
  final double stickerPrice;
  @JsonKey(defaultValue: 0)
  final double finalPrice;

  @JsonKey(defaultValue: DiscountType.finalPrice)
  final DiscountType discountType;

  SaleItem({
    required this.categoryId,
    required this.qty,
    required this.stickerPrice,
    required this.finalPrice,
    required this.categoryName,
    required this.discountType,
  });

  double get discountPercent {
    if (stickerPrice == 0) return 0.0;
    return ((stickerPrice - finalPrice) / stickerPrice) * 100;
  }

  double get unitDiscountAmount {
    return stickerPrice - finalPrice;
  }

  double get totalAmount {
    return qty * finalPrice;
  }

  // --- JSON Logic ---
  factory SaleItem.fromJson(Map<String, dynamic> json) =>
      _$SaleItemFromJson(json);

  Map<String, dynamic> toJson() => _$SaleItemToJson(this);
}
