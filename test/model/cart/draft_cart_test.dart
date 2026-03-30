import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/model/cart/draft_cart.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  // 1. Setup Mock Data
  final mockCategory = Category(
    id: 'c1',
    name: 'Necklace',
    currentStock: 0,
    isHotkey: false,
    billMachineNumber: 0,
  );

  final mockItems = [
    CartItem(
      category: mockCategory,
      stickerPrice: 2000.0,
      discountPercent: 10.0,
      quantity: 1,
    ),
  ];

  final testDate = DateTime(2026, 3, 30, 23, 0, 0);

  group('DraftCart Model Tests', () {
    test('should correctly create an instance from constructor', () {
      final cart = DraftCart(
        id: 'draft_123',
        customerName: 'Manikanta',
        customerPhone: '8121971462',
        items: mockItems,
        total: 1800.0,
        createdAt: testDate,
      );

      expect(cart.customerName, 'Manikanta');
      expect(cart.items.length, 1);
      expect(cart.total, 1800.0);
    });

    test('copyWithId should return new instance with updated ID', () {
      final cart = DraftCart(
        id: 'old_id',
        customerName: 'Lavanya',
        customerPhone: '9999999999',
        items: mockItems,
        total: 1800.0,
        createdAt: testDate,
      );

      final newCart = cart.copyWithId('new_id');

      expect(newCart.id, 'new_id');
      expect(newCart.customerName, 'Lavanya'); // Should remain same
      expect(
        identical(cart, newCart),
        isFalse,
      ); // Should be a different instance
    });

    group('JSON Serialization', () {
      test('toJson should preserve camelCase and explicit objects', () {
        final cart = DraftCart(
          id: 'draft_123',
          customerName: 'Manikanta',
          customerPhone: '8121971462',
          items: mockItems,
          total: 1800.0,
          createdAt: testDate,
        );

        final json = cart.toJson();

        expect(json['customerName'], 'Manikanta');
        expect(json['total'], 1800.0);
        expect(json['items'], isA<List>());
        // Check if items inside also serialized correctly
        expect(json['items'][0]['stickerPrice'], 2000.0);
      });

      test('fromJson should handle a full data map', () {
        final json = {
          'id': 'temp_id',
          'customerName': 'Suresh',
          'customerPhone': '7777777777',
          'total': 900.0,
          'createdAt': Timestamp.fromDate(
            testDate,
          ), // Simulated Firestore Timestamp
          'items': [
            {
              'category': {
                'id': 'c1',
                'name': 'Ring',
                'icon': 'ring_icon',
                'billMachineNumber': 1,
                'currentStock': 10,
                'isHotkey': false,
              },
              'stickerPrice': 1000.0,
              'discountPercent': 10.0,
              'quantity': 1,
            },
          ],
        };

        final cart = DraftCart.fromJson(json);

        expect(cart.customerName, 'Suresh');
        expect(cart.items.first.category.name, 'Ring');
        expect(cart.createdAt.year, 2026);
      });
    });
  });
}
