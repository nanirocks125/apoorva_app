import 'package:apoorva_app/screens/checkout/bill_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TextEditingController roundOffController;

  setUp(() {
    roundOffController = TextEditingController(text: '0');
  });

  tearDown(() {
    roundOffController.dispose();
  });

  Future<void> pumpBillCard(
    WidgetTester tester, {
    required double mrp,
    required double discOnMrp,
    required double addDisc,
    required double net,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BillSummaryCard(
            totalMrp: mrp,
            totalDiscountOnMRP: discOnMrp,
            additionalDiscount: addDisc,
            netTotal: net,
            roundOffController: roundOffController,
          ),
        ),
      ),
    );
  }

  group('BillSummaryCard Scenarios', () {
    testWidgets('Scenario 1: No Discounts Applied', (
      WidgetTester tester,
    ) async {
      await pumpBillCard(
        tester,
        mrp: 500.0,
        discOnMrp: 0.0,
        addDisc: 0.0,
        net: 500.0,
      );

      // Verify Labels
      expect(find.text('Total MRP'), findsOneWidget);
      expect(find.text('Bill Amount'), findsOneWidget);
      expect(find.text('NET TOTAL'), findsOneWidget);

      // Verify Values:
      // 1 (MRP) + 1 (Bill Amount) + 1 (Net Total) = 3 widgets
      expect(find.text('₹500.00'), findsNWidgets(3));

      // Hidden rows
      expect(find.text('Item Discounts'), findsNothing);
      expect(find.text('Subtotal'), findsNothing);
    });

    testWidgets('Scenario 2: Only Item Discounts Applied', (
      WidgetTester tester,
    ) async {
      await pumpBillCard(
        tester,
        mrp: 1000.0,
        discOnMrp: 100.0,
        addDisc: 0.0,
        net: 900.0,
      );

      expect(find.text('Item Discounts'), findsOneWidget);
      expect(find.text('- ₹100.00'), findsOneWidget);

      // Subtotal and Additional Discount should still be hidden because addDisc is 0
      expect(find.text('Subtotal'), findsNothing);
      expect(find.text('Additional Discount'), findsNothing);

      // Bill Amount should reflect MRP - Item Discount
      expect(
        find.text('₹900.00'),
        findsNWidgets(2),
      ); // Bill Amount and NET TOTAL
    });

    testWidgets(
      'Scenario 3: Additional Discount Only (Triggers Subtotal View)',
      (WidgetTester tester) async {
        await pumpBillCard(
          tester,
          mrp: 1000.0,
          discOnMrp: 0.0,
          addDisc: 50.0,
          net: 950.0,
        );

        // Since addDisc > 0, Subtotal row must appear
        expect(find.text('Subtotal'), findsOneWidget);
        expect(
          find.text('₹1000.00'),
          findsNWidgets(2),
        ); // MRP and Subtotal (since item disc is 0)

        expect(find.text('Additional Discount'), findsOneWidget);
        expect(find.text('- ₹50.00'), findsOneWidget);

        expect(find.text('Bill Amount'), findsOneWidget);
        expect(
          find.text('₹950.00'),
          findsNWidgets(2),
        ); // Bill Amount and NET TOTAL
      },
    );

    testWidgets('Scenario 4: Fully Loaded (Both Discounts + Dividers)', (
      WidgetTester tester,
    ) async {
      // Logic Check:
      // MRP: 1000
      // Item Disc: 100 -> Subtotal: 900
      // Add Disc: 50 -> Bill Amount: 850
      await pumpBillCard(
        tester,
        mrp: 1000.0,
        discOnMrp: 100.0,
        addDisc: 50.0,
        net: 850.0,
      );

      expect(find.text('Item Discounts'), findsOneWidget);
      expect(find.text('- ₹100.00'), findsOneWidget);

      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('₹900.00'), findsOneWidget);

      expect(find.text('Additional Discount'), findsOneWidget);
      expect(find.text('- ₹50.00'), findsOneWidget);

      expect(find.text('Bill Amount'), findsOneWidget);
      expect(
        find.text('₹850.00'),
        findsNWidgets(2),
      ); // Bill Amount and NET TOTAL
    });

    testWidgets('Scenario 5: Round-off Interaction', (
      WidgetTester tester,
    ) async {
      roundOffController.text = '0.75';
      await pumpBillCard(
        tester,
        mrp: 100.0,
        discOnMrp: 0.0,
        addDisc: 0.0,
        net: 99.25,
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '0.75');

      expect(find.text('₹99.25'), findsOneWidget); // Net Total
    });

    testWidgets('Scenario 6: Visual/Style Verification', (
      WidgetTester tester,
    ) async {
      await pumpBillCard(
        tester,
        mrp: 100.0,
        discOnMrp: 10.0,
        addDisc: 5.0,
        net: 85.0,
      );

      // Verify Discount Colors
      final itemDiscText = tester.widget<Text>(find.text('- ₹10.00'));
      expect(itemDiscText.style?.color, Colors.green.shade700);

      final addDiscText = tester.widget<Text>(find.text('- ₹5.00'));
      expect(addDiscText.style?.color, Colors.green.shade700);

      // Verify Net Total Styling
      final netTotalText = tester.widget<Text>(find.text('NET TOTAL'));
      expect(netTotalText.style?.fontWeight, FontWeight.bold);
      expect(netTotalText.style?.fontSize, 18.0);
    });
  });
}
