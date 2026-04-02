import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:apoorva_app/screens/pos/pos_ui_helpers.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';

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
    when(() => mockProvider.updateItem(any(), any())).thenReturn(null);

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
        createTestScreen((context) {
          PosUIHelpers.openCalculator(
            context,
            mockProvider,
            category: category,
          );
        }),
      );

      // 1. Bottom sheet ని ఓపెన్ చేయడం
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 2. UI వెరిఫికేషన్
      expect(find.text('Adding Gold Ring'), findsOneWidget);

      // 3. Price ఎంటర్ చేయడం
      await tester.enterText(find.byType(TextField), '5000');

      // 4. Discount 10% సెలెక్ట్ చేయడం
      await tester.tap(find.text('10%'));
      await tester.pump();

      // 5. Final Price వెరిఫై చేయడం: 5000 - 10% = 4500.00
      expect(find.text('₹4500.00'), findsOneWidget);

      // 6. Add button క్లిక్ చేయడం
      await tester.tap(find.text('ADD TO CART'));
      await tester.pumpAndSettle();

      // 7. Verify addItem was called
      verify(() => mockProvider.addItem(any())).called(1);
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
