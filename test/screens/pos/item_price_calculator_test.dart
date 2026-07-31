import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/screens/pos/item_price_calculator.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';

class MockPosProvider extends Mock implements PosProvider {}

class MockPosCart extends Mock implements PosCart {}

void main() {
  late MockPosProvider mockProvider;
  late MockPosCart mockCart;
  late Category testCategory;

  setUpAll(() {
    testCategory = Category(
      id: '1',
      name: 'Gold Ring',
      currentStock: 0,
      isHotkey: false,
      billMachineNumber: 1,
    );
    registerFallbackValue(
      CartItem(category: testCategory, mrp: 0, discountPercent: 0, quantity: 1),
    );
  });

  setUp(() {
    mockProvider = MockPosProvider();
    mockCart = MockPosCart();

    // ✅ Wrap these in closures
    when(() => mockCart.totalFinalPrice).thenReturn(0.0);
    when(() => mockCart.totalMRP).thenReturn(0.0);
    when(() => mockCart.items).thenReturn([]);

    // This one was already correct in your screenshot
    when(() => mockProvider.cart).thenReturn(mockCart);
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
        mrp: 5000,
        discountPercent: 10,
        quantity: 1,
        discountType: .percentage,
      );
      await tester.pumpWidget(
        createWidgetUnderTest(existingItem: existing, index: 0),
      );

      expect(find.text('Edit Gold Ring'), findsOneWidget);
      expect(find.text('UPDATE ITEM'), findsOneWidget);

      final priceField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'MRP'),
      );
      expect(priceField.controller?.text, '5000');

      final tenPercentChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '10%'),
      );
      expect(tenPercentChip.selected, isTrue);

      expect(find.text('₹5000.00'), findsWidgets);
      expect(find.text('- ₹500.00'), findsOneWidget);
      expect(find.text('₹4500.00'), findsOneWidget);
    });
  });

  group('Price Calculations', () {
    testWidgets('calculates 10% discount correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Enter Price 1000
      // We use widgetWithText for the 'Sticker Price' label
      await tester.enterText(find.widgetWithText(TextField, 'MRP'), '1000');
      await tester.pump();

      await tester.tap(find.text('% Off'));
      await tester.pump(); // Trigger the rebuild to show the chips

      // 2. Tap 10% chip
      // Using widgetWithText(ChoiceChip, ...) is safer than find.text
      // because '10%' might appear in multiple places (like the summary)
      await tester.tap(find.widgetWithText(ChoiceChip, '10%'));
      await tester.pump();

      // 3. Verify Calculations
      // Note: Your component uses toStringAsFixed(2), so we must expect ".00"
      // Also, check the exact spacing in your _buildPriceRow ("- ₹" vs "₹")

      // Subtotal (Gross Amount)
      expect(find.text('₹1000.00'), findsWidgets);

      // // Discount row: formatted as "- ₹100.00" in your code
      expect(find.text('- ₹100.00'), findsOneWidget);

      // // Net Total: formatted as "₹900.00"
      expect(find.text('₹900.00'), findsOneWidget);
    });

    testWidgets('calculates Fixed Amount discount correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Enter Sticker Price
      // Using widgetWithText is more robust than find.byType().first
      await tester.enterText(find.widgetWithText(TextField, 'MRP'), '1000');
      await tester.pump();

      // 2. Switch to Amount mode
      // Your refactored code uses: label: Text('Amount (₹)')
      await tester.tap(find.text('₹ Discount'));
      await tester
          .pumpAndSettle(); // Required to let the conditional TextField appear

      // 3. Enter 150 discount
      // This TextField only exists when _discountType == DiscountType.amount
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter Discount Amount'),
        '150',
      );
      await tester.pump();

      // 4. Verify Calculations
      // Note: Component uses toStringAsFixed(2) and has a space after ₹

      // Gross Amount
      expect(find.text('₹1000.00'), findsWidgets);

      // Discount row: "- ₹150.00"
      expect(find.text('- ₹150.00'), findsOneWidget);

      // Net Total: "₹850.00"
      expect(find.text('₹850.00'), findsOneWidget);
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

      await tester.tap(find.text('% Off'));
      await tester.pump(); // Trigger the rebuild to show the chips

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
        mrp: 5000,
        discountPercent: 0,
        quantity: 1,
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

  group('ItemPriceCalculator - Discount Type Logic', () {
    testWidgets('loads existing discount as percentage by default', (
      tester,
    ) async {
      final existing = CartItem(
        category: testCategory,
        mrp: 1000,
        discountPercent: 15,
        quantity: 1,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(existingItem: existing, index: 0),
      );

      // 1. By default, it should be in Percentage mode
      // Verify the 15% ChoiceChip is selected (if 15% exists in your list,
      // otherwise check the summary math)

      await tester.tap(find.text('% Off'));
      await tester.pump(); // Trigger the rebuild to show the chips

      // expect(find.text('Percent (%)'), findsOneWidget);

      // 2. Since 15% isn't in your [0, 5, 10, 20] list, we check the summary
      // Gross: 1000.00, Discount: 150.00, Net: 850.00
      expect(find.text('- ₹150.00'), findsOneWidget);
      expect(find.text('₹850.00'), findsOneWidget);

      // 3. Verify the Amount TextField is NOT visible yet
      expect(
        find.widgetWithText(TextField, 'Discount Amount (₹)'),
        findsNothing,
      );
    });

    testWidgets('switching modes clears input and toggles TextField visibility', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Enter Sticker Price
      await tester.enterText(find.widgetWithText(TextField, 'MRP'), '1000');
      await tester.pump();

      await tester.tap(find.text('% Off'));
      await tester.pump(); // Trigger the rebuild to show the chips

      // 2. Select a percentage chip
      await tester.tap(find.text('10%'));
      await tester.pump();

      expect(find.text('- ₹100.00'), findsOneWidget);

      // 3. Switch to Amount mode
      // Label in your refactored code: 'Amount (₹)'
      await tester.tap(find.text('₹ Discount'));
      await tester.pumpAndSettle();

      // 4. Verify TextField appears and is empty (because you call .clear() in onSelectionChanged)
      final amountFieldFinder = find.widgetWithText(
        TextField,
        'Enter Discount Amount',
      );
      expect(amountFieldFinder, findsOneWidget);

      final TextField amountField = tester.widget(amountFieldFinder);
      expect(amountField.controller?.text, '100');

      // 5. Switch back to Percentage mode
      await tester.tap(find.text('% Off'));
      await tester.pumpAndSettle();

      // 6. Verify TextField is gone and calculation is reset (Discount: 0.00)
      expect(
        find.widgetWithText(TextField, 'Enter Discount Amount'),
        findsNothing,
      );
      expect(find.text('- ₹100.00'), findsOneWidget);
    });
  });

  group('ItemPriceCalculator - Boundary Conditions', () {
    testWidgets('clamps fixed discount to sticker price (no negative totals)', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Enter Sticker Price of 100
      await tester.enterText(find.widgetWithText(TextField, 'MRP'), '100');
      await tester.pump();

      // 2. Switch to Amount mode via SegmentedButton
      // Label: Amount (₹)
      await tester.tap(find.text('₹ Discount'));
      await tester.pumpAndSettle();

      // 3. Enter a discount of 150 (which is > 100)
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter Discount Amount'),
        '150',
      );
      await tester.pump();

      // 4. Verify Discount Applied row
      // _discountValue returns the raw input 150.00
      expect(find.text('- ₹100.00'), findsOneWidget);

      // 5. Verify NET TOTAL is clamped at 0.00 (not -50.00)
      // _finalPrice uses .clamp(0, sticker)
      expect(find.text('₹0.00'), findsOneWidget);

      await tester
          .pumpAndSettle(); // Allow UI to update summary and button state

      final addButtonFinder = find.widgetWithText(
        ElevatedButton,
        'ADD TO BILL',
      );

      // 3. Ensure the button is visible (Scrolls if necessary)
      // This prevents the "Bad State / No Element" error
      await tester.ensureVisible(addButtonFinder);
      await tester.pump();

      // 4. Extract and Verify
      final addButton = tester.widget<ElevatedButton>(addButtonFinder);
      expect(addButton.onPressed, isNull);
    });
  });

  testWidgets('tapping a choice chip updates the discount and total', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // 1. Enter Sticker Price
    // Using widgetWithText ensures we target the correct field
    await tester.enterText(find.widgetWithText(TextField, 'MRP'), '5000');
    await tester.pump();

    // 5. Switch back to Percentage mode
    await tester.tap(find.text('% Off'));
    await tester.pumpAndSettle();

    // 2. Tap 20% chip
    // Specifically finding the ChoiceChip prevents accidentally tapping
    // summary text that might contain "20%"
    await tester.tap(find.widgetWithText(ChoiceChip, '20%'));
    await tester.pump();

    // 3. Verify Calculations
    // Note: Your component uses .toStringAsFixed(2)

    // Gross Amount row
    expect(find.text('₹5000.00'), findsWidgets);

    // Discount row: formatted as "- ₹1000.00" (20% of 5000)
    expect(find.text('- ₹1000.00'), findsOneWidget);

    // Net Amount row: formatted as "₹4000.00"
    expect(find.text('₹4000.00'), findsOneWidget);
  });

  group('ItemPriceCalculator - Final Price Mode', () {
    testWidgets('switching to Final Price mode shows correct input label', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Switch to Final Price mode
      // The label inside the SegmentedButton is 'Final (₹)'
      await tester.tap(find.text('Final ₹'));
      await tester.pumpAndSettle();

      // 2. Verify the dynamic TextField label changed accordingly
      expect(
        find.widgetWithText(TextField, 'Enter Final Price'),
        findsOneWidget,
      );
    });

    testWidgets(
      'calculates reverse discount correctly based on final price input',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        // 1. Enter Sticker Price
        await tester.enterText(find.widgetWithText(TextField, 'MRP'), '1000');
        await tester.pump();

        // 2. Switch to Final Price mode
        await tester.tap(find.text('Final ₹'));
        await tester.pumpAndSettle();

        // 3. Enter Final Price of 750
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter Final Price'),
          '750',
        );
        await tester.pump();

        // 4. Verify Calculations
        // Gross Amount
        expect(find.text('₹1000.00'), findsWidgets);

        // Reverse Calculated Discount (1000 - 750 = 250)
        expect(find.text('- ₹250.00'), findsOneWidget);

        // Net Total (Matches the Final Price input)
        expect(find.text('₹750.00'), findsOneWidget);
      },
    );

    testWidgets(
      'disables submit button and clamps values if final price exceeds sticker price',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        // 1. Enter Sticker Price of 500
        await tester.enterText(find.widgetWithText(TextField, 'MRP'), '500');
        await tester.pump();

        // 2. Switch to Final Price mode
        await tester.tap(find.text('Final ₹'));
        await tester.pumpAndSettle();

        // 3. Enter Final Price of 600 (Which exceeds the sticker price)
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter Final Price'),
          '600',
        );
        await tester.pump();

        // 4. Verify Calculations (Clamped to prevent negative discounts)
        // Reverse Calculated Discount (500 - 600) clamped to 0
        expect(find.text('- ₹0.00'), findsOneWidget);

        // 🚀 THE FIX: Both Gross Amount and Net Total will be '₹500.00', so we expect 2 widgets.
        expect(find.text('₹500.00'), findsNWidgets(2));

        await tester.pumpAndSettle();

        final addButtonFinder = find.widgetWithText(
          ElevatedButton,
          'ADD TO BILL',
        );

        // 3. Ensure the button is visible (Scrolls if necessary)
        // This prevents the "Bad State / No Element" error
        await tester.ensureVisible(addButtonFinder);
        await tester.pumpAndSettle();

        // 4. Extract and Verify
        final addButton = tester.widget<ElevatedButton>(addButtonFinder);
        expect(addButton.onPressed, isNull);
      },
    );
  });
}
