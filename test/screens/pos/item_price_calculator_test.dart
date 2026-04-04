import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/screens/pos/item_price_calculator.dart'; // Path మార్చండి
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPosProvider extends Mock implements PosProvider {}

void main() {
  late MockPosProvider mockProvider;
  late Category testCategory;

  setUpAll(() {
    registerFallbackValue(
      CartItem(
        category: Category(
          id: '1',
          name: 'T',
          currentStock: 0,
          billMachineNumber: 0,
          isHotkey: true,
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
      name: 'Bangles',
      currentStock: 10,
      billMachineNumber: 5,
      isHotkey: true,
    );
  });

  Widget createWidget({CartItem? existingItem, int? index}) {
    return MaterialApp(
      home: Scaffold(
        body: CalculatorSheet(
          provider: mockProvider,
          category: testCategory,
          existingItem: existingItem,
          index: index,
        ),
      ),
    );
  }

  group('CalculatorSheet - UI & Calculation Logic', () {
    testWidgets('Renders "New" mode correctly', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.text('New Bangles'), findsOneWidget);
      expect(find.text('ADD TO BILL'), findsOneWidget);
    });

    testWidgets('Renders "Edit" mode with existing data', (tester) async {
      final existing = CartItem(
        category: testCategory,
        stickerPrice: 1000,
        discountPercent: 10,
      );
      await tester.pumpWidget(createWidget(existingItem: existing, index: 0));

      expect(find.text('Edit Bangles'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('UPDATE ITEM'), findsOneWidget);
    });

    testWidgets('Calculates final price correctly in Percentage mode', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextField, 'Sticker Price'),
        '2000',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Discount %'),
        '20',
      );
      await tester.pump();

      // Calculation: 2000 - (20% of 2000) = 1600
      expect(find.text('₹1600.00'), findsOneWidget);
      expect(find.text('- ₹400.00'), findsOneWidget);
    });

    testWidgets('Switches to Amount mode and clears discount input', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextField, 'Sticker Price'),
        '1000',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Discount %'),
        '10',
      );

      // Switch to Amount mode
      await tester.tap(find.byIcon(Icons.currency_rupee));
      await tester.pumpAndSettle();

      // Verify controller is cleared
      final discountField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Discount Amount (₹)'),
      );
      expect(discountField.controller?.text, '');

      // Enter flat discount
      await tester.enterText(find.byType(TextField).last, '150');
      await tester.pump();

      expect(find.text('₹850.00'), findsOneWidget);
      expect(find.text('- ₹150.00'), findsOneWidget);
    });

    testWidgets('Quick percent chips update the discount value', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.tap(find.text('30%'));
      await tester.pump();

      final discountField = tester.widget<TextField>(
        find.byType(TextField).last,
      );
      expect(discountField.controller?.text, '30');
    });
  });

  group('CalculatorSheet - Keyboard & Focus', () {
    testWidgets('Dismisses keyboard on outer tap', (tester) async {
      await tester.pumpWidget(createWidget());

      final priceField = find.widgetWithText(TextField, 'Sticker Price');

      // 1. Focus the TextField
      await tester.tap(priceField);
      await tester.pump(); // Allow focus to update

      // 2. Verify TextField HAS focus
      final FocusNode priceFocusNode =
          tester.widget<TextField>(priceField).focusNode ??
          FocusScope.of(tester.element(priceField)).focusedChild!;
      expect(priceFocusNode.hasFocus, isTrue);

      // 3. Tap outside (the title text) to trigger GestureDetector unfocus
      await tester.tap(find.text('New Bangles'));
      await tester.pump();

      // 4. Verify TextField LOST focus
      expect(priceFocusNode.hasFocus, isFalse);
    });

    testWidgets('Closes keyboard on "Done" action', (tester) async {
      await tester.pumpWidget(createWidget());

      final discountField = find.widgetWithText(TextField, 'Discount %');

      // 1. Focus the field
      await tester.tap(discountField);
      await tester.pump();

      // Get the focus node
      final FocusNode discountFocusNode = FocusScope.of(
        tester.element(discountField),
      ).focusedChild!;
      expect(discountFocusNode.hasFocus, isTrue);

      // 2. Send "Done" action
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // 3. Verify focus is released
      expect(discountFocusNode.hasFocus, isFalse);
    });
  });

  group('CalculatorSheet - Persistence', () {
    testWidgets('Calls addItem when creating new item', (tester) async {
      when(() => mockProvider.addItem(any())).thenReturn(null);

      await tester.pumpWidget(createWidget());
      await tester.enterText(find.byType(TextField).first, '1000');
      await tester.enterText(find.byType(TextField).last, '10');
      await tester.pump();

      await tester.tap(find.text('ADD TO BILL'));
      await tester.pumpAndSettle();

      verify(() => mockProvider.addItem(any())).called(1);
    });

    testWidgets('Converts Amount discount back to Percentage for model', (
      tester,
    ) async {
      when(() => mockProvider.addItem(any())).thenReturn(null);

      await tester.pumpWidget(createWidget());
      await tester.enterText(find.byType(TextField).first, '1000');

      // Switch to Amount
      await tester.tap(find.byIcon(Icons.currency_rupee));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '250'); // 25%

      await tester.tap(find.text('ADD TO BILL'));
      await tester.pumpAndSettle();

      final captured =
          verify(() => mockProvider.addItem(captureAny())).captured.first
              as CartItem;
      // Calculation: (250 / 1000) * 100 = 25
      expect(captured.discountPercent, 25.0);
    });

    testWidgets('Calls updateItem when index is provided', (tester) async {
      final existing = CartItem(
        category: testCategory,
        stickerPrice: 500,
        discountPercent: 0,
      );
      when(() => mockProvider.updateItem(any(), any())).thenReturn(null);

      await tester.pumpWidget(createWidget(existingItem: existing, index: 2));
      await tester.tap(find.text('UPDATE ITEM'));
      await tester.pumpAndSettle();

      verify(() => mockProvider.updateItem(2, any())).called(1);
    });
  });
}
