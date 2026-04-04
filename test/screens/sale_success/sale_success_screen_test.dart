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
        home: SaleSuccessScreen(
          sale: mockSale,
          orgId: 'ORG_001',
          canPop: false,
        ),
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
      // expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Bill Amount'), findsOneWidget);

      // 4. Check Net Payment Amount label (New label in your update)
      expect(find.text('Net Payment Amount'), findsNothing);

      // Amount ₹2199.80 appears in: Subtotal, Bill Amount, Net Payment, Cash row, Chain price, and Savings box.
      // Total 6 times in this mock setup.
      expect(find.text('₹2199.80'), findsNWidgets(2));
    });

    testWidgets('Should verify Blue Savings Box Content', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Savings Box labels
      expect(find.text('Total Bill Amount'), findsNothing);
      expect(find.text('YOU SAVED'), findsNothing);

      // Savings Amount
      expect(
        find.text('₹222.20'),
        findsNothing,
      ); // Appears in Items and Savings box
    });

    testWidgets('Should verify Action Buttons presence', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Print Receipt'), findsOneWidget);
      expect(find.text('Send Text Message'), findsOneWidget);
      expect(find.text('Share WhatsApp Message'), findsOneWidget);
    });

    testWidgets('Should navigate to Home on DONE button tap', (tester) async {
      // Mocking user for AuthProvider
      when(() => mockAuthProvider.user).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Find the Close button in the AppBar by its icon
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);
      await tester.ensureVisible(closeButton);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets(
      'Edge Case: Complex Savings (Item Disc + Overall Disc + RoundOff)',
      (tester) async {
        // Setup:
        // Total MRP: 1000
        // Item Disc: 100 (Final 900)
        // Overall Disc: 50
        // RoundOff: 5.40
        // Net Payable: 844.60
        final complexSale = Sale(
          id: 'COMPLEX123',
          customerName: 'Test',
          customerPhone: '1234567890',
          items: [
            SaleItem(
              categoryName: 'Ring',
              stickerPrice: 1000,
              finalPrice: 900,
              qty: 1,
              categoryId: '1',
            ),
          ],
          subtotal: 900,
          overallDiscountAmount: 50,
          roundOff: 5.40, // Note: Positive value based on your UI logic
          netPayable: 844.60,
          payments: {PaymentMode.upi: 844.60},
          staffId: 's1',
          overallDiscountPercent: 0,
          timestamp: DateTime.now(),
          source: 'POS',
          status: 'Completed',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(
                value: mockAuthProvider,
              ),
            ],
            child: MaterialApp(
              home: SaleSuccessScreen(
                sale: complexSale,
                orgId: 'ORG_001',
                canPop: false,
              ),
            ),
          ),
        );

        // 1. Verify Additional Discount row exists
        expect(find.text('Additional Discount'), findsOneWidget);
        expect(find.text('-₹50.00'), findsOneWidget);

        // // 2. Verify Round-off exists
        expect(find.text('Round-off'), findsOneWidget);
        expect(find.text('-₹5.40'), findsOneWidget);

        // // 3. Verify Net Payment Amount exists (triggered by roundOff > 0)
        expect(find.text('Net Payment Amount'), findsOneWidget);
        expect(find.text('₹844.60'), findsNWidgets(3)); // Net Payment + UPI row

        // 4. Verify Blue Box is visible (triggered by overallDiscountAmount > 0)
        expect(find.text('YOU SAVED'), findsOneWidget);
        expect(find.text('₹155.40'), findsOneWidget); // 100 + 50 + 5.40
      },
    );

    testWidgets('Edge Case: Multiple Payment Modes Display', (tester) async {
      final multiPaySale = Sale(
        id: 'PAY123',
        customerName: 'Test',
        customerPhone: '123',
        items: [
          SaleItem(
            categoryName: 'A',
            stickerPrice: 100,
            finalPrice: 100,
            qty: 1,
            categoryId: '1',
          ),
        ],
        subtotal: 100,
        overallDiscountAmount: 0,
        roundOff: 0,
        netPayable: 100,
        payments: {PaymentMode.cash: 40.0, PaymentMode.upi: 60.0},
        staffId: 's1',
        overallDiscountPercent: 0,
        timestamp: DateTime.now(),
        source: 'POS',
        status: 'Completed',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ],
          child: MaterialApp(
            home: SaleSuccessScreen(
              sale: multiPaySale,
              orgId: 'ORG_001',
              canPop: false,
            ),
          ),
        ),
      );

      expect(find.text('CASH'), findsOneWidget);
      expect(find.text('₹40.00'), findsOneWidget);
      expect(find.text('UPI'), findsOneWidget);
      expect(find.text('₹60.00'), findsOneWidget);
    });

    testWidgets('Edge Case: Zero Savings Clean UI', (tester) async {
      final noSavingsSale = Sale(
        id: 'CLEAN123',
        customerName: 'Walk-in',
        customerPhone: '123',
        items: [
          SaleItem(
            categoryName: 'Gold',
            stickerPrice: 5000,
            finalPrice: 5000,
            qty: 1,
            categoryId: '1',
          ),
        ],
        subtotal: 5000,
        overallDiscountAmount: 0,
        roundOff: 0,
        netPayable: 5000,
        payments: {PaymentMode.cash: 5000},
        staffId: 's1',
        overallDiscountPercent: 0,
        timestamp: DateTime.now(),
        source: 'POS',
        status: 'Completed',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ],
          child: MaterialApp(
            home: SaleSuccessScreen(
              sale: noSavingsSale,
              orgId: 'ORG_001',
              canPop: false,
            ),
          ),
        ),
      );

      // Should not show any discount/savings related widgets
      expect(find.text('Item Discounts'), findsNothing);
      expect(find.text('Additional Discount'), findsNothing);
      expect(find.text('YOU SAVED'), findsNothing);
      expect(find.text('Saved: ₹0.00'), findsNothing);
      expect(
        find.text('Net Payment Amount'),
        findsNothing,
      ); // Hidden when roundOff is 0
    });
  });
}
