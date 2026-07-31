import 'package:apoorva_app/model/sale_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaleItem Model Tests', () {
    group('Constructor & Logic', () {
      test('should initialize all fields correctly', () {
        final item = SaleItem(
          categoryId: 'gold_01',
          categoryName: 'Bangles',
          qty: 2,
          stickerPrice: 2000.0,
          finalPrice: 1800.0,
          discountType: .finalPrice,
        );

        expect(item.categoryId, 'gold_01');
        expect(item.qty, 2);
        expect(item.stickerPrice, 2000.0);
      });

      test('discountPercent should calculate correctly', () {
        final item = SaleItem(
          categoryId: 'c1',
          categoryName: 'Ring',
          qty: 1,
          stickerPrice: 1000.0,
          finalPrice: 900.0,
          discountType: .finalPrice,
        );

        // (1000 - 900) / 1000 * 100 = 10%
        expect(item.discountPercent, 10.0);
      });

      test('discountPercent should return 0.0 if stickerPrice is 0', () {
        final item = SaleItem(
          categoryId: 'c1',
          categoryName: 'Free Gift',
          qty: 1,
          stickerPrice: 0.0,
          finalPrice: 0.0,
          discountType: .finalPrice,
        );

        expect(item.discountPercent, 0.0);
      });
    });

    group('JSON Serialization', () {
      test('toJson should map categoryId to "cat_id"', () {
        final item = SaleItem(
          categoryId: 'chain_55',
          categoryName: 'Necklace',
          qty: 1,
          stickerPrice: 5000.0,
          finalPrice: 4500.0,
          discountType: .finalPrice,
        );

        final json = item.toJson();

        // Testing the @JsonKey(name: 'cat_id') mapping
        expect(json['cat_id'], 'chain_55');
        expect(json['categoryName'], 'Necklace');
        expect(json['stickerPrice'], 5000.0);
      });

      test('fromJson should handle "cat_id" and provide default values', () {
        final json = {
          'cat_id': 'bangle_09',
          'stickerPrice': 3000.0,
          'finalPrice': 2700.0,
          // 'categoryName' and 'qty' are missing to test default values
        };

        final item = SaleItem.fromJson(json);

        expect(item.categoryId, 'bangle_09');
        expect(item.categoryName, ''); // Default value from @JsonKey
        expect(item.qty, 0); // Default value from @JsonKey
        expect(item.discountPercent, 10.0);
      });
    });
  });
}
