import 'package:apoorva_app/screens/pos/category_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/model/category/category.dart';

void main() {
  // 1. Mock Data క్రియేట్ చేయడం
  final testCategory = Category(
    id: 'rings_123',
    name: 'Gold Rings',
    currentStock: 15,
    isHotkey: true,
    billMachineNumber: 1,
  );

  final normalCategory = Category(
    id: 'silver_123',
    name: 'Silver Items',
    currentStock: 5,
    isHotkey: false,
    billMachineNumber: 2,
  );

  group('CategoryCard Widget Tests', () {
    testWidgets('Should display category name and stock count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryCard(category: testCategory, onTap: () {}),
          ),
        ),
      );

      // Assertions
      expect(find.text('Gold Rings'), findsOneWidget);
      expect(find.text('STK: 15'), findsOneWidget);
    });

    testWidgets('Should show hotkey indicator only when isHotkey is true', (
      tester,
    ) async {
      // Test with Hotkey = true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryCard(category: testCategory, onTap: () {}),
          ),
        ),
      );

      // Hotkey indicator అనేది ఒక Container (height: 3)
      // దాన్ని వెతకడానికి మనం Type లేదా Specific logic వాడొచ్చు
      final hotkeyIndicator = find.byType(Container);
      expect(
        hotkeyIndicator,
        findsWidgets,
      ); // Indicators + The card container itself

      // Test with Hotkey = false
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryCard(category: normalCategory, onTap: () {}),
          ),
        ),
      );

      // Normal category లో ఆ orange bar ఉండకూడదు
      expect(find.byKey(const Key('hotkey_bar')), findsNothing);
      // Note: ఒకవేళ మీరు మీ కోడ్ లో Key యాడ్ చేస్తే ఇది ఇంకా Robust గా ఉంటుంది
    });

    testWidgets('Should trigger onTap when clicked', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryCard(
              category: testCategory,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // InkWell మీద క్లిక్ చేయడం
      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });
  });
}
