import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

// Project Imports
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/model/sale_item.dart';
import 'package:apoorva_app/enum/payment_mode.dart';
import 'package:apoorva_app/providers/auth_provider.dart';
import 'package:apoorva_app/screens/sale_success/sale_success_screen.dart';

// Mocks
class MockAuthProvider extends Mock implements AuthProvider {}

void main() {
  late Sale mockSale;
  late MockAuthProvider mockAuthProvider;

  setUpAll(() {
    registerFallbackValue(MaterialPageRoute(builder: (_) => Container()));
  });

  setUp(() {
    mockAuthProvider = MockAuthProvider();

    // Mock Data based on your current math logic:
    // Total MRP: 200 + 2222 = 2422
    // Item Discounts: (2222 - 1999.80) = 222.20
    // Subtotal: 2199.80
    // Net Payable: 2199.80
    // Total Savings: 222.20
    mockSale = Sale(
      id: 'TUQSYH12345',
      customerName: 'Manikanta',
      customerPhone: '9876543210',
      items: [
        SaleItem(
          categoryName: 'Earrings',
          stickerPrice: 200,
          finalPrice: 200.00,
          qty: 1,
          categoryId: 'cat_1',
        ),
        SaleItem(
          categoryName: 'Chain',
          stickerPrice: 2222,
          finalPrice: 1999.80,
          qty: 1,
          categoryId: 'cat_2',
        ),
      ],
      subtotal: 2199.80,
      overallDiscountAmount: 0,
      roundOff: 0,
      netPayable: 2199.80,
      payments: {PaymentMode.cash: 2199.80},
      staffId: 'staff_1',
      overallDiscountPercent: 0,
      timestamp: DateTime.now(),
      source: 'POS',
      status: 'Completed',
    );
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/home') {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Home Page')),
            );
          }
          return null;
        },
        home: SaleSuccessScreen(sale: mockSale, orgId: 'ORG_001'),
      ),
    );
  }

  group('SaleSuccessScreen Logic & UI Tests', () {
    testWidgets('Should display correct Header and ID', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Sale Successful!'), findsOneWidget);
      expect(find.textContaining('TUQSYH12345'), findsOneWidget);
    });

    testWidgets('Should verify Financial Summary Tiered Logic', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Check Total MRP
      expect(
        find.text('Total MRP'),
        findsWidgets,
      ); // Appears in Summary and Savings Box
      expect(find.text('₹2422.00'), findsWidgets);

      // 2. Check Item Discounts
      expect(find.text('Item Discounts'), findsOneWidget);
      expect(find.text('-₹222.20'), findsOneWidget);

      // 3. Check Subtotal & Bill Amount
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Bill Amount'), findsOneWidget);

      // 4. Check Net Payment Amount label (New label in your update)
      expect(find.text('Net Payment Amount'), findsOneWidget);

      // Amount ₹2199.80 appears in: Subtotal, Bill Amount, Net Payment, Cash row, Chain price, and Savings box.
      // Total 6 times in this mock setup.
      expect(find.text('₹2199.80'), findsNWidgets(5));
    });

    testWidgets('Should verify Blue Savings Box Content', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Savings Box labels
      expect(find.text('Total Bill Amount'), findsOneWidget);
      expect(find.text('YOU SAVED'), findsOneWidget);

      // Savings Amount
      expect(
        find.text('₹222.20'),
        findsWidgets,
      ); // Appears in Items and Savings box
    });

    testWidgets('Should verify Action Buttons presence', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Print Receipt'), findsOneWidget);
      expect(find.text('Send Text Message'), findsOneWidget);
      expect(find.text('Generate & Share PDF'), findsOneWidget);
      expect(find.text('Share WhatsApp Message'), findsOneWidget);
      expect(find.text('Share PDF on WhatsApp'), findsOneWidget);
    });

    testWidgets('Should navigate to Home on DONE button tap', (tester) async {
      // Mocking user for AuthProvider
      when(() => mockAuthProvider.user).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      final doneButton = find.text('DONE - NEW SALE');
      await tester.ensureVisible(doneButton);
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });
  });
}
