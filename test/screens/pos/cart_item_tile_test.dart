import 'package:apoorva_app/screens/pos/cart_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/category/category.dart';

void main() {
  // 1. Mock Data క్రియేట్ చేయడం
  final testCategory = Category(
    id: 'gold_chain',
    name: 'Gold Chain',
    currentStock: 5,
    isHotkey: true,
    billMachineNumber: 1,
  );

  final testItem = CartItem(
    category: testCategory,
    mrp: 5000.0,
    discountPercent: 10.0,
    quantity: 1,
  );

  group('CartItemTile Widget Tests', () {
    testWidgets('Should display correct item details (Name, Price, Discount)', (
      WidgetTester tester,
    ) async {
      // Widget ని లోడ్ చేయడం
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemTile(item: testItem, onTap: () {}, onRemove: () {}),
          ),
        ),
      );

      // Assertions
      expect(find.text('Gold Chain'), findsOneWidget);
      // 🚀 STICKER PRICE FIX: విడ్జెట్ లో 5000.0 ని render చేస్తే ₹5000.0 వస్తుంది
      // ఒకవేళ విడ్జెట్ లో కూడా .toInt() వాడితే ఇక్కడ ₹5000 అని ఇవ్వండి.
      expect(find.textContaining('₹5000'), findsOneWidget);
      expect(find.textContaining('10% Off'), findsOneWidget);

      // 🚀 FINAL PRICE FIX: విడ్జెట్ లో .toInt() వాడారు కాబట్టి 4500 అని ఉండాలి
      expect(find.text('₹4500.00'), findsOneWidget);
      expect(find.text('G'), findsOneWidget);
    });

    testWidgets('Should trigger onTap when the card is clicked', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemTile(
              item: testItem,
              onTap: () => tapped = true,
              onRemove: () {},
            ),
          ),
        ),
      );

      // Card మీద క్లిక్ చేయడం
      await tester.tap(find.byType(ListTile));
      await tester.pump();
      expect(tapped, true);
    });

    testWidgets('Should trigger onRemove when the remove icon is clicked', (
      WidgetTester tester,
    ) async {
      bool removed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemTile(
              item: testItem,
              onTap: () {},
              onRemove: () => removed = true,
            ),
          ),
        ),
      );

      // Remove Icon మీద క్లిక్ చేయడం
      await tester.tap(find.byIcon(Icons.remove_circle_outline_rounded));
      await tester.pump();
      expect(removed, true);
    });
  });
}
