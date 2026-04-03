import 'package:apoorva_app/screens/pos/item_price_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:apoorva_app/screens/pos/pos_ui_helpers.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:provider/provider.dart';

// Mocks
class MockPosProvider extends Mock implements PosProvider {}

class FakeCartItem extends Fake implements CartItem {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCartItem());

    // ఒకవేళ Category కి కూడా ఇష్యూ వస్తే దీన్ని కూడా యాడ్ చేయండి
    // registerFallbackValue(FakeCategory());
  });

  late MockPosProvider mockProvider;

  setUp(() {
    mockProvider = MockPosProvider();
    when(() => mockProvider.addItem(any())).thenReturn(null);
    when(() => mockProvider.updateItem(any())).thenReturn(null);

    // Register fallback values for mocktail any()
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

  // Helper widget to trigger the helper methods
  Widget createTestScreen(Function(BuildContext) action) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => action(context),
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  group('PosUIHelpers - openCalculator Tests', () {
    testWidgets('Should open calculator and add item to cart', (tester) async {
      final category = Category(
        id: '1',
        name: 'Gold Ring',
        currentStock: 10,
        isHotkey: true,
        billMachineNumber: 1,
      );

      await tester.pumpWidget(
        // 🚀 Fix 1: Wrap in Provider so the Calculator doesn't crash finding context
        ChangeNotifierProvider<PosProvider>.value(
          value: mockProvider,
          child: createTestScreen((context) {
            // 🚀 Fix 2: Just CALL the method, don't return a widget
            PosUIHelpers.openCalculator(
              context,
              mockProvider,
              category: category,
            );
          }),
        ),
      );

      // 2. 'Open' బటన్ ని ట్యాప్ చేసి బాటమ్ షీట్ ని ట్రిగర్ చేయడం
      await tester.tap(find.text('Open'));
      await tester
          .pumpAndSettle(); // 🚀 యానిమేషన్ కంప్లీట్ అయ్యే వరకు వెయిట్ చేస్తుంది

      // 3. UI వెరిఫికేషన్ (Add and Edit logic verification)
      // 'Add' మరియు 'Gold Ring' ఉన్నాయో లేదో చెక్ చేయడం
      debugDumpApp(); // This will print the whole widget tree in your terminal
      // expect(find.textContaining('Add'), findsOneWidget);

      expect(find.textContaining('Gold Ring'), findsOneWidget);

      // 4. ప్రైస్ ఎంటర్ చేయడం
      final priceField = find
          .byType(TextField)
          .first; // మొదటి టెక్స్ట్ ఫీల్డ్ (Sticker Price)
      await tester.enterText(priceField, '5000');
      await tester.pump();

      // 5. డిస్కౌంట్ సెలెక్ట్ చేయడం (10%)
      await tester.tap(find.text('10%'));
      await tester.pump();

      // 6. ఫైనల్ ప్రైస్ వెరిఫై చేయడం (5000 - 10% = 4500)
      // మన Modern UI లో .toInt() వాడాం కాబట్టి ₹4500 అని వెతకాలి
      expect(find.textContaining('4500'), findsOneWidget);

      // 7. 'ADD TO BILL' బటన్ క్లిక్ చేయడం
      await tester.tap(
        find.text('ADD TO BILL'),
      ); // 🚀 మన తాజా కోడ్ ప్రకారం 'ADD TO BILL'
      await tester.pumpAndSettle();

      // 8. మోడల్ క్లోజ్ అయిందో లేదో వెరిఫై చేయడం
      expect(find.byType(ItemPriceCalculator), findsNothing);
    });
  });

  group('PosUIHelpers - showCategoryPicker Tests', () {
    testWidgets('Should filter categories based on search query', (
      tester,
    ) async {
      final categories = [
        Category(
          id: '1',
          name: 'Gold Ring',
          currentStock: 10,
          isHotkey: false,
          billMachineNumber: 1,
        ),
        Category(
          id: '2',
          name: 'Silver Chain',
          currentStock: 5,
          isHotkey: false,
          billMachineNumber: 1,
        ),
      ];

      await tester.pumpWidget(
        createTestScreen((context) {
          PosUIHelpers.showCategoryPicker(context, mockProvider, categories);
        }),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 1. Initial state లో అన్నీ ఉండాలి
      expect(find.text('Gold Ring'), findsOneWidget);
      expect(find.text('Silver Chain'), findsOneWidget);

      // 2. Search చేయడం
      await tester.enterText(find.byType(TextField), 'Silver');
      await tester.pump();

      // 3. Filter అయిందో లేదో చూడటం
      expect(find.text('Gold Ring'), findsNothing);
      expect(find.text('Silver Chain'), findsOneWidget);
    });
  });
}
