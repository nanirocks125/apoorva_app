import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/screens/pos/cart_item_tile.dart';
import 'package:apoorva_app/screens/pos/cart_list_section.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

// 1. Mocks Definition
class MockPosProvider extends Mock implements PosProvider {}

class MockPosCart extends Mock implements PosCart {}

void main() {
  late MockPosProvider mockProvider;
  late MockPosCart mockCart;

  setUp(() {
    mockProvider = MockPosProvider();
    mockCart = MockPosCart();

    // ప్రతి టెస్ట్ కి ముందు డిఫాల్ట్ గా ఒక కార్ట్ ని రిటర్న్ చేయమని చెప్పడం
    when(() => mockProvider.cart).thenReturn(mockCart);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<PosProvider>.value(
          value: mockProvider,
          child: const CustomScrollView(slivers: [CartListSection()]),
        ),
      ),
    );
  }

  group('CartListSection Tests', () {
    testWidgets('Should show empty message when cart is empty', (tester) async {
      // items ఖాళీగా ఉన్నాయని చెప్పడం
      when(() => mockCart.items).thenReturn([]);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text("Cart is empty"), findsOneWidget);
      expect(find.byType(CartItemTile), findsNothing);
    });

    testWidgets('Should show list of items when cart has data', (tester) async {
      final items = [
        CartItem(
          category: Category(
            id: '1',
            name: 'Gold Ring',
            currentStock: 5,
            isHotkey: true,
            billMachineNumber: 1,
          ),
          stickerPrice: 1000,
          discountPercent: 0,
        ),
        CartItem(
          category: Category(
            id: '2',
            name: 'Silver Chain',
            currentStock: 10,
            isHotkey: false,
            billMachineNumber: 2,
          ),
          stickerPrice: 500,
          discountPercent: 10,
        ),
      ];

      // Mock Cart లో items ఉన్నాయని చెప్పడం
      when(() => mockCart.items).thenReturn(items);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CartItemTile), findsNWidgets(2));
      expect(find.text('Gold Ring'), findsOneWidget);
      expect(find.text('Silver Chain'), findsOneWidget);
    });

    testWidgets('Should call removeItem when remove button is clicked', (
      tester,
    ) async {
      final items = [
        CartItem(
          category: Category(
            id: '1',
            name: 'Gold Ring',
            currentStock: 5,
            isHotkey: true,
            billMachineNumber: 1,
          ),
          stickerPrice: 1000,
          discountPercent: 0,
        ),
      ];

      when(() => mockCart.items).thenReturn(items);
      when(() => mockProvider.removeItem(any())).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());

      // CartItemTile లోపల ఉన్న IconButton ని క్లిక్ చేయడం
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();

      verify(() => mockProvider.removeItem(0)).called(1);
    });
  });
}
