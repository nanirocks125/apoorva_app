import 'package:apoorva_app/enum/payment_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

// Project Imports
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/model/sale_item.dart';
import 'package:apoorva_app/providers/auth_provider.dart';
import 'package:apoorva_app/screens/sale_success_screen.dart';

// Mocks
class MockAuthProvider extends Mock implements AuthProvider {}

// Note: Ensure PaymentType enum matches your actual model (e.g., .cash vs 'cash')
enum PaymentType { cash, upi }

void main() {
  late Sale mockSale;
  late MockAuthProvider mockAuthProvider;

  setUpAll(() {
    registerFallbackValue(MaterialPageRoute(builder: (_) => Container()));
  });

  setUp(() {
    mockAuthProvider = MockAuthProvider();

    // SCREENSHOT 2 లో ఉన్న డేటా ప్రకారం Mock Sale ఆబ్జెక్ట్
    mockSale = Sale(
      id: 'TuQSYHq0zTrjOEl2dYyi',
      customerName: 'Customer',
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
      subtotal: 2199.80, // స్క్రీన్ షాట్ ప్రకారం డిస్కౌంటెడ్ సబ్ టోటల్
      overallDiscountAmount: 0,
      roundOff: 0,
      netPayable: 2199.80,
      payments: {PaymentMode.cash: 2199.80}, // Note: Lowercase 'cash'
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

  group('SaleSuccessScreen UI Tests (Screenshot Validated)', () {
    testWidgets(
      'Should render success message and exact Sale ID from Screenshot',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());

        expect(find.text('Sale Successful!'), findsOneWidget);
        expect(find.textContaining('TuQSYHq0zTrjOEl2dYyi'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      },
    );

    testWidgets('Should display earrings and chain with correct math', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.pumpWidget(createWidgetUnderTest());

      // స్క్రీన్ మీద 3 చోట్ల ఈ అమౌంట్ కనిపిస్తుంది:
      // 1. Subtotal, 2. Net Payable, 3. Payment details (cash)
      expect(find.text('₹2199.80'), findsNWidgets(3));

      // Item Savings row (మైనస్ గుర్తుతో ఉంటుంది)
      expect(find.text('-₹222.20'), findsOneWidget);

      // YOU SAVED Banner (మైనస్ లేకుండా బ్లూ కలర్‌లో ఉంటుంది)
      expect(find.text('₹222.20'), findsOneWidget);
    });

    testWidgets('Should handle lowercase payment mode label', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // స్క్రీన్ షాట్ లో 'cash' అని ఉంది, 'Cash' కాదు.
      expect(find.text('cash'), findsOneWidget);
      expect(find.text('₹2199.80'), findsWidgets);
    });
  });

  group('Interaction Tests', () {
    testWidgets('Should navigate to /home when DONE is pressed', (
      tester,
    ) async {
      when(() => mockAuthProvider.user).thenReturn(null);
      await tester.pumpWidget(createWidgetUnderTest());

      final doneButton = find.text('DONE - NEW SALE');
      await tester.ensureVisible(doneButton);
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('Visible Action buttons should be present', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Print Receipt'), findsOneWidget);
      expect(find.text('Send Text Message'), findsOneWidget);
    });
  });
}
