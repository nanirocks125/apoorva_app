import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/screens/pos/item_price_calculator.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';

class MockPosProvider extends Mock implements PosProvider {}

void main() {
  late MockPosProvider mockProvider;
  late Category testCategory;

  setUpAll(() {
    registerFallbackValue(
      CartItem(
        category: Category(
          id: '1',
          name: 'Test',
          currentStock: 0,
          isHotkey: false,
          billMachineNumber: 1,
        ),
        stickerPrice: 0,
        discountPercent: 0,
      ),
    );
  });

  setUp(() {
    mockProvider = MockPosProvider();
    testCategory = Category(
      id: 'cat_1',
      name: 'Gold Ring',
      currentStock: 10,
      isHotkey: true,
      billMachineNumber: 1,
    );
  });

  Widget createWidgetUnderTest({CartItem? existingItem, int? index}) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<PosProvider>.value(
          value: mockProvider,
          child: ItemPriceCalculator(
            provider: mockProvider,
            category: testCategory,
            existingItem: existingItem,
            index: index,
          ),
        ),
      ),
    );
  }

  group('Rendering Modes', () {
    testWidgets('shows "Add Gold Ring" and "ADD TO BILL" in add mode', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Add Gold Ring'), findsOneWidget);
      expect(find.text('ADD TO BILL'), findsOneWidget);
    });

    testWidgets('shows "Edit Gold Ring" and "UPDATE ITEM" in edit mode', (
      tester,
    ) async {
      final existing = CartItem(
        category: testCategory,
        stickerPrice: 5000,
        discountPercent: 10,
      );
      await tester.pumpWidget(createWidgetUnderTest(existingItem: existing));

      expect(find.text('Edit Gold Ring'), findsOneWidget);
      expect(find.text('UPDATE ITEM'), findsOneWidget);
      // Verify initial price is loaded
      expect(find.text('5000'), findsOneWidget);
    });
  });

  group('Price Calculations', () {
    testWidgets('calculates 10% discount correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter Price 1000
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.pump();

      // Tap 10% chip
      await tester.tap(find.text('10%'));
      await tester.pump();

      // Subtotal: 1000, Discount: 100, Net: 900
      expect(find.text('₹1000'), findsWidgets); // Subtotal row
      expect(find.text('-₹100'), findsOneWidget); // Discount row
      expect(find.text('₹900'), findsOneWidget); // Net Total
    });

    testWidgets('calculates Fixed Amount discount correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter Price 1000
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.pump();

      // Switch to Fixed Amount
      await tester.tap(find.text('Fixed Amount ₹'));
      await tester.pumpAndSettle();

      // Enter 150 discount
      await tester.enterText(find.byType(TextField).last, '150');
      await tester.pump();

      expect(find.text('-₹150'), findsOneWidget);
      expect(find.text('₹850'), findsOneWidget);
    });
  });

  group('Validation', () {
    testWidgets('submit button is disabled when price is 0', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final btnFinder = find.byType(ElevatedButton);
      final ElevatedButton btn = tester.widget(btnFinder);

      expect(btn.onPressed, isNull); // Disabled
    });

    testWidgets('submit button is enabled when price > 0', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byType(TextField).first, '100');
      await tester.pump();

      final btnFinder = find.byType(ElevatedButton);
      final ElevatedButton btn = tester.widget(btnFinder);

      expect(btn.onPressed, isNotNull); // Enabled
    });
  });

  group('Submission Actions', () {
    testWidgets('calls addItem on provider when adding new', (tester) async {
      when(() => mockProvider.addItem(any())).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byType(TextField).first, '2000');
      await tester.tap(find.text('5%'));
      await tester.pump();

      await tester.tap(find.text('ADD TO BILL'));
      await tester.pumpAndSettle();

      // Verify addItem was called once
      verify(() => mockProvider.addItem(any())).called(1);
    });

    testWidgets('calls updateItem on provider when editing', (tester) async {
      final existing = CartItem(
        category: testCategory,
        stickerPrice: 5000,
        discountPercent: 0,
      );
      when(() => mockProvider.updateItem(any(), any())).thenReturn(null);

      await tester.pumpWidget(
        createWidgetUnderTest(existingItem: existing, index: 0),
      );

      // Change price to 6000
      await tester.enterText(find.byType(TextField).first, '6000');
      await tester.pump();

      await tester.tap(find.text('UPDATE ITEM'));
      await tester.pumpAndSettle();

      verify(() => mockProvider.updateItem(any(), any())).called(1);
    });
  });
}
