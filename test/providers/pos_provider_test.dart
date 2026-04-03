import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/services/draft_cart_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/model/cart/draft_cart.dart';

// Mocking the Service
class MockDraftCartService extends Mock implements DraftCartService {}

void main() {
  late PosProvider posProvider;
  const String testOrgId = 'apoorva_mangalagiri';

  // Dummy Category & Item for testing
  final testCategory = Category(
    id: 'gold_ring',
    name: 'Gold Ring',
    currentStock: 10,
    isHotkey: true,
    billMachineNumber: 1,
  );

  final testItem = CartItem(
    category: testCategory,
    stickerPrice: 1000.0,
    discountPercent: 10.0,
  );

  setUp(() {
    posProvider = PosProvider(orgId: testOrgId);
  });

  tearDown(() {
    posProvider.dispose();
  });

  group('PosProvider - Basic Cart Operations', () {
    test('Initial state should be empty', () {
      expect(posProvider.cart.items.isEmpty, true);
      expect(posProvider.nameController.text, '');
      expect(posProvider.activeDraftId, null);
    });

    test('addItem should add item and notify listeners', () {
      posProvider.addItem(testItem);
      expect(posProvider.cart.items.length, 1);
      expect(posProvider.cart.items.first.category.name, 'Gold Ring');
    });

    test('removeItem should remove item at specific index', () {
      posProvider.addItem(testItem);
      posProvider.removeItem(0);
      expect(posProvider.cart.items.isEmpty, true);
    });

    test('updateItem should replace existing item', () {
      posProvider.addItem(testItem);
      final updatedItem = CartItem(
        category: testCategory,
        stickerPrice: 2000.0,
        discountPercent: 5.0,
      );
      posProvider.updateItem(updatedItem, 0);
      expect(posProvider.cart.items.first.stickerPrice, 2000.0);
    });
  });

  group('PosProvider - Draft & Clear Logic', () {
    test('clearCart should reset all controllers and cart', () {
      posProvider.addItem(testItem);
      posProvider.nameController.text = 'Manikanta';
      posProvider.clearCart();

      expect(posProvider.cart.items.isEmpty, true);
      expect(posProvider.nameController.text, '');
      expect(posProvider.activeDraftId, null);
    });

    test('resumeDraft should populate provider with draft data', () {
      final draft = DraftCart(
        id: 'draft_123',
        customerName: 'Apoorva Client',
        customerPhone: '9876543210',
        items: [testItem],
        total: 900.0,
        createdAt: DateTime.now(),
      );

      posProvider.resumeDraft('draft_123', draft);

      expect(posProvider.activeDraftId, 'draft_123');
      expect(posProvider.nameController.text, 'Apoorva Client');
      expect(posProvider.cart.items.length, 1);
    });
  });
}
