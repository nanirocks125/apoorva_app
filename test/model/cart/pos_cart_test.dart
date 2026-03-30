import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/category/category.dart';

void main() {
  // Setup Mock Category
  final mockCategory = Category(
    id: 'c1',
    name: 'Bangles',
    currentStock: 10,
    isHotkey: true,
    billMachineNumber: 1,
  );

  group('PosCart Model Tests', () {
    test('initial state should have 0 items and 0.0 totalPayable', () {
      final cart = PosCart();
      expect(cart.items, isEmpty);
      expect(cart.totalPayable, 0.0);
      expect(cart.paymentMode, 'Cash');
    });

    test('totalPayable should sum multiple items correctly', () {
      final cart = PosCart();

      // Item 1: 1000 - 10% = 900
      cart.items.add(
        CartItem(
          category: mockCategory,
          stickerPrice: 1000.0,
          discountPercent: 10.0,
          quantity: 1,
        ),
      );

      // Item 2: 500 * 2 = 1000
      cart.items.add(
        CartItem(
          category: mockCategory,
          stickerPrice: 500.0,
          discountPercent: 0.0,
          quantity: 2,
        ),
      );

      // 900 + 1000 = 1900
      expect(cart.totalPayable, 1900.0);
    });

    test('flatDiscount should subtract from subtotal correctly', () {
      final cart = PosCart();
      cart.items.add(
        CartItem(category: mockCategory, stickerPrice: 2000.0, quantity: 1),
      );

      cart.flatDiscount = 200.0; // ₹200 off the whole cart

      // 2000 - 200 = 1800
      expect(cart.totalPayable, 1800.0);
    });

    test('totalPayable should never be negative (clamping test)', () {
      final cart = PosCart();
      cart.items.add(
        CartItem(category: mockCategory, stickerPrice: 100.0, quantity: 1),
      );

      cart.flatDiscount = 500.0; // Discount is higher than price

      // Should be 0.0, not -400.0
      expect(cart.totalPayable, 0.0);
    });

    test('should store customer and social metadata correctly', () {
      final cart = PosCart();
      cart.customerName = 'Manikanta';
      cart.customerPhone = '8121971462';
      cart.socialSource = 'Instagram';

      expect(cart.customerName, 'Manikanta');
      expect(cart.socialSource, 'Instagram');
    });
  });
}
