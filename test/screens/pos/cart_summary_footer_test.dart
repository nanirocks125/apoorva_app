import 'package:apoorva_app/screens/pos/cart_summary_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';

// Mocks Definition
class MockPosProvider extends Mock implements PosProvider {}

class MockPosCart extends Mock implements PosCart {}

void main() {
  // ఈ మెయిన్ ఫంక్షన్ కచ్చితంగా ఉండాలి
  late MockPosProvider mockProvider;
  late MockPosCart mockCart;

  setUp(() {
    mockProvider = MockPosProvider();
    mockCart = MockPosCart();

    // Default stubbing
    when(() => mockProvider.cart).thenReturn(mockCart);
    when(() => mockProvider.orgId).thenReturn('apoorva_mangalagiri');
    when(() => mockProvider.activeDraftId).thenReturn(null);
    when(() => mockProvider.nameController).thenReturn(TextEditingController());
    when(
      () => mockProvider.phoneController,
    ).thenReturn(TextEditingController());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<PosProvider>.value(
          value: mockProvider,
          child: const CartSummaryFooter(),
        ),
      ),
    );
  }

  group('CartSummaryFooter Widget Tests', () {
    testWidgets('Should show correct items count and total price', (
      tester,
    ) async {
      when(() => mockCart.items).thenReturn([]); // Empty for initial check
      when(() => mockCart.totalPayable).thenReturn(0.0);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('0 ITEMS'), findsOneWidget);
      expect(find.text('₹0.00'), findsOneWidget);
    });

    testWidgets('Checkout button should be disabled when cart is empty', (
      tester,
    ) async {
      when(() => mockCart.items).thenReturn([]);
      when(() => mockCart.totalPayable).thenReturn(0.0);

      await tester.pumpWidget(createWidgetUnderTest());

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
