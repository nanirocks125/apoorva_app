import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:apoorva_app/screens/pos/cart_summary_footer.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

// Mocks
class MockPosProvider extends Mock implements PosProvider {}

class MockPosCart extends Mock implements PosCart {}

class MockCartItem extends Mock implements CartItem {}

void main() {
  late MockPosProvider mockProvider;
  late MockPosCart mockCart;

  setUp(() {
    mockProvider = MockPosProvider();
    mockCart = MockPosCart();

    // ✅ 1. Stub exactly as doubles (0.0) to match the model and avoid Null errors
    when(() => mockCart.totalItemsCount).thenReturn(0);
    when(() => mockCart.totalPayable).thenReturn(0.0);
    when(() => mockCart.items).thenReturn(<CartItem>[]);

    // ✅ 2. Stub Provider with all necessary dependencies
    when(() => mockProvider.cart).thenReturn(mockCart);
    when(() => mockProvider.orgId).thenReturn('apoorva_mangalagiri');
    when(() => mockProvider.activeDraftId).thenReturn(null);
    when(() => mockProvider.billDateTime).thenReturn(DateTime.now());
    when(() => mockProvider.nameController).thenReturn(TextEditingController());
    when(
      () => mockProvider.phoneController,
    ).thenReturn(TextEditingController());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: ChangeNotifierProvider<PosProvider>.value(
          value: mockProvider,
          child: CartSummaryFooter(),
        ),
      ),
    );
  }

  group('CartSummaryFooter Widget Tests', () {
    testWidgets('Should show correct items count and total price', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // ✅ 3. Match the string exactly. If count is a double, it renders as "0.0 ITEMS"
      // Use find.textContaining or a Regex to be safe across different number formats
      expect(find.textContaining('0.00'), findsOneWidget);
      expect(find.textContaining('ITEMS'), findsOneWidget);
      expect(find.text('₹0.00'), findsOneWidget);
    });

    testWidgets('Checkout button should be disabled when cart is empty', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Checkout button should be enabled when cart has items', (
      tester,
    ) async {
      final mockItem = MockCartItem();

      when(() => mockCart.items).thenReturn(<CartItem>[mockItem]);
      when(() => mockCart.totalItemsCount).thenReturn(1);
      when(() => mockCart.totalPayable).thenReturn(500.0);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for the rendered double value
      expect(find.textContaining('1'), findsOneWidget);
      expect(find.text('₹500.00'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });
  });
}
