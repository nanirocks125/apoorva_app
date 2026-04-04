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
      expect(find.text('10%'), findsOneWidget);
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

      await tester.tap(find.widgetWithText(ChoiceChip, '20%'));
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
      await tester.tap(find.widgetWithText(ChoiceChip, '10%'));

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
  });
  group('CalculatorSheet - Keyboard & Focus', () {
    testWidgets('Dismisses keyboard on outer tap', (tester) async {
      await tester.pumpWidget(createWidget());

      // Use "Sticker Price" because it is ALWAYS visible
      final priceField = find.widgetWithText(TextField, 'Sticker Price');
      await tester.tap(priceField);
      await tester.pump();

      // Check focus
      final FocusNode priceFocusNode = FocusScope.of(
        tester.element(priceField),
      ).focusedChild!;
      expect(priceFocusNode.hasFocus, isTrue);

      // Tap title to unfocus
      await tester.tap(find.text('New Bangles'));
      await tester.pump();

      expect(priceFocusNode.hasFocus, isFalse);
    });

    testWidgets('Closes keyboard on "Done" action (Amount Mode)', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      // 1. Switch to Amount mode so the Discount TextField appears
      await tester.tap(find.byIcon(Icons.currency_rupee));
      await tester.pumpAndSettle();

      final discountField = find.widgetWithText(
        TextField,
        'Discount Amount (₹)',
      );
      await tester.tap(discountField);
      await tester.pump();

      // 2. Verify focus
      final FocusNode discountFocusNode = FocusScope.of(
        tester.element(discountField),
      ).focusedChild!;
      expect(discountFocusNode.hasFocus, isTrue);

      // 3. Send "Done" action
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // 4. Verify focus is released
      expect(discountFocusNode.hasFocus, isFalse);
    });
  });

  group('CalculatorSheet - Amount Mode Logic', () {
    testWidgets('Calculates final price correctly in Amount mode', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextField, 'Sticker Price'),
        '5000',
      );

      // Switch to Amount Mode
      await tester.tap(find.byIcon(Icons.currency_rupee));
      await tester.pumpAndSettle();

      // Enter Discount Amount
      await tester.enterText(
        find.widgetWithText(TextField, 'Discount Amount (₹)'),
        '750',
      );
      await tester.pump();

      // 5000 - 750 = 4250
      expect(find.text('₹4250.00'), findsOneWidget);
      expect(find.text('- ₹750.00'), findsOneWidget);
    });

    testWidgets('Disables ADD TO BILL if discount amount > sticker price', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextField, 'Sticker Price'),
        '100',
      );
      await tester.tap(find.byIcon(Icons.currency_rupee));
      await tester.pumpAndSettle();

      // Invalid discount
      await tester.enterText(
        find.widgetWithText(TextField, 'Discount Amount (₹)'),
        '150',
      );
      await tester.pump();

      final addButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(addButton.onPressed, isNull);
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

  group('CalculatorSheet - Amount Mode Logic', () {
    testWidgets('Calculates final price correctly in Amount mode', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      // 1. Enter Sticker Price
      await tester.enterText(
        find.widgetWithText(TextField, 'Sticker Price'),
        '5000',
      );

      // 2. Switch to Amount Mode (Rupee Icon)
      await tester.tap(find.byIcon(Icons.currency_rupee));
      await tester.pumpAndSettle();

      // 3. Enter Discount Amount
      await tester.enterText(
        find.widgetWithText(TextField, 'Discount Amount (₹)'),
        '750',
      );
      await tester.pump();

      // Calculation: 5000 - 750 = 4250
      expect(find.text('₹4250.00'), findsOneWidget);
      expect(find.text('- ₹750.00'), findsOneWidget);
    });

    testWidgets('Disables ADD TO BILL if discount amount > sticker price', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextField, 'Sticker Price'),
        '100',
      );

      // Switch to Amount mode
      await tester.tap(find.byIcon(Icons.currency_rupee));
      await tester.pumpAndSettle();

      // Enter discount higher than price
      await tester.enterText(
        find.widgetWithText(TextField, 'Discount Amount (₹)'),
        '150',
      );
      await tester.pump();

      // The final price should clamp to 0 or logic should disable the button
      expect(find.text('₹0.00'), findsOneWidget);

      final addButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(addButton.onPressed, isNull);
    });

    testWidgets(
      'Persistent data correctly maps Amount discount to Percentage',
      (tester) async {
        when(() => mockProvider.addItem(any())).thenReturn(null);
        await tester.pumpWidget(createWidget());

        await tester.enterText(
          find.widgetWithText(TextField, 'Sticker Price'),
          '2000',
        );

        // Switch to Amount mode
        await tester.tap(find.byIcon(Icons.currency_rupee));
        await tester.pumpAndSettle();

        // Enter 500 (which is 25% of 2000)
        await tester.enterText(
          find.widgetWithText(TextField, 'Discount Amount (₹)'),
          '500',
        );
        await tester.pump();

        await tester.tap(find.text('ADD TO BILL'));
        await tester.pumpAndSettle();

        // Verify the model received 25%
        final captured =
            verify(() => mockProvider.addItem(captureAny())).captured.first
                as CartItem;
        expect(captured.discountPercent, 25.0);
      },
    );
  });
}
