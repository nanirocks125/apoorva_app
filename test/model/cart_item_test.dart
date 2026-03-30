import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/category/category.dart';

void main() {
  // We need a dummy category to satisfy the CartItem constructor
  final mockCategory = Category(
    id: 'cat_123',
    name: 'Gold Chain',
    currentStock: 0,
    isHotkey: true,
    billMachineNumber: 1,
  );

  group('CartItem Model Tests', () {
    group('finalPrice Calculation', () {
      test('should calculate correctly with 0% discount and 1 quantity', () {
        final item = CartItem(
          category: mockCategory,
          stickerPrice: 1000.0,
          discountPercent: 0.0,
          quantity: 1,
        );

        expect(item.finalPrice, 1000.0);
      });

      test('should calculate correctly with 10% discount', () {
        final item = CartItem(
          category: mockCategory,
          stickerPrice: 1000.0,
          discountPercent: 10.0,
          quantity: 1,
        );

        // 1000 - 10% = 900
        expect(item.finalPrice, 900.0);
      });

      test(
        'should calculate correctly with multiple quantities and discount',
        () {
          final item = CartItem(
            category: mockCategory,
            stickerPrice: 500.0,
            discountPercent: 20.0,
            quantity: 2,
          );

          // (500 * 2) = 1000. 1000 - 20% = 800
          expect(item.finalPrice, 800.0);
        },
      );

      test('should handle 100% discount correctly', () {
        final item = CartItem(
          category: mockCategory,
          stickerPrice: 1234.0,
          discountPercent: 100.0,
        );

        expect(item.finalPrice, 0.0);
      });
    });

    group('JSON Serialization', () {
      test('toJson should return a valid Map with correct values', () {
        final item = CartItem(
          category: mockCategory,
          stickerPrice: 2000.0,
          discountPercent: 5.0,
          quantity: 1,
        );

        final json = item.toJson();

        expect(json['stickerPrice'], 2000.0);
        expect(json['discountPercent'], 5.0);
        expect(json['category']['name'], 'Gold Chain');
      });

      test('fromJson should create a valid CartItem object', () {
        final json = {
          'category': mockCategory.toJson(),
          'stickerPrice': 3000.0,
          'discountPercent': 10.0,
          'quantity': 2,
        };

        final item = CartItem.fromJson(json);

        expect(item.category.name, 'Gold Chain');
        expect(item.stickerPrice, 3000.0);
        expect(item.finalPrice, 5400.0); // (3000 * 2) - 10%
      });
    });
  });
}
