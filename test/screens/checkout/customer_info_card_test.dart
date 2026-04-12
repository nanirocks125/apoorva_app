import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/screens/checkout/customer_info_card.dart';

void main() {
  // Helper to wrap the widget in a MaterialApp for testing
  Widget createWidgetUnderTest(Customer customer) {
    return MaterialApp(
      home: Scaffold(body: CustomerInfoCard(customer: customer)),
    );
  }

  group('CustomerInfoCard Widget Tests', () {
    testWidgets(
      'Scenario 1: Displays default text when customer data is empty',
      (tester) async {
        final emptyCustomer = Customer(
          name: '',
          phone: '',
          createdAt: DateTime(2026, 2, 2),
          lastPurchaseDate: DateTime(2026, 2, 2),
        );

        await tester.pumpWidget(createWidgetUnderTest(emptyCustomer));

        // Check for default "Walk-in" labels
        expect(find.text('Walk-in Customer'), findsOneWidget);
        expect(find.text('No Phone'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario 2: Displays actual name but default phone when only name is provided',
      (tester) async {
        final nameOnly = Customer(
          name: 'Manikanta',
          phone: '',
          createdAt: DateTime(2026, 2, 2),
          lastPurchaseDate: DateTime(2026, 2, 2),
        );

        await tester.pumpWidget(createWidgetUnderTest(nameOnly));

        expect(find.text('Manikanta'), findsOneWidget);
        expect(find.text('No Phone'), findsOneWidget);
        expect(find.text('Walk-in Customer'), findsNothing);
      },
    );

    testWidgets(
      'Scenario 3: Displays default name but actual phone when only phone is provided',
      (tester) async {
        final phoneOnly = Customer(
          name: '',
          phone: '9876543210',
          createdAt: DateTime(2026, 2, 2),
          lastPurchaseDate: DateTime(2026, 2, 2),
        );

        await tester.pumpWidget(createWidgetUnderTest(phoneOnly));

        expect(find.text('Walk-in Customer'), findsOneWidget);
        expect(find.text('9876543210'), findsOneWidget);
        expect(find.text('No Phone'), findsNothing);
      },
    );

    testWidgets(
      'Scenario 4: Displays both name and phone when both are provided',
      (tester) async {
        final fullCustomer = Customer(
          name: 'Apoorva',
          phone: '1234567890',
          createdAt: DateTime(2026, 2, 2),
          lastPurchaseDate: DateTime(2026, 2, 2),
        );

        await tester.pumpWidget(createWidgetUnderTest(fullCustomer));

        expect(find.text('Apoorva'), findsOneWidget);
        expect(find.text('1234567890'), findsOneWidget);
      },
    );

    testWidgets('Scenario 5: Verify text styling', (tester) async {
      final customer = Customer(
        name: 'Style Test',
        phone: '000',
        createdAt: DateTime(2026, 2, 2),
        lastPurchaseDate: DateTime(2026, 2, 2),
      );
      await tester.pumpWidget(createWidgetUnderTest(customer));

      // Find the name text widget
      final Text nameText = tester.widget(find.text('Style Test'));
      expect(nameText.style?.fontWeight, FontWeight.bold);
      expect(nameText.style?.fontSize, 16.0);

      // Find the phone text widget
      final Text phoneText = tester.widget(find.text('000'));
      expect(phoneText.style?.color, Colors.grey.shade600);
    });
  });
}
