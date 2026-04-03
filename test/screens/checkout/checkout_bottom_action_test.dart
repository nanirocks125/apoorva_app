import 'package:apoorva_app/screens/checkout/checkout_bottom_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helper to wrap and pump the widget
  Future<void> pumpBottomAction(
    WidgetTester tester, {
    required double balance,
    bool isProcessing = false,
    bool canConfirm = false,
    VoidCallback? onConfirm,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CheckoutBottomAction(
            balance: balance,
            isProcessing: isProcessing,
            canConfirm: canConfirm,
            onConfirm: onConfirm ?? () {},
          ),
        ),
      ),
    );
  }

  group('CheckoutBottomAction UI Tests', () {
    testWidgets('Scenario 1: Positive balance displays "Due" in Red', (
      WidgetTester tester,
    ) async {
      await pumpBottomAction(tester, balance: 50.0);

      final labelText = find.text('Due');
      final amountText = find.text('₹50.00');

      expect(labelText, findsOneWidget);
      expect(amountText, findsOneWidget);

      // Verify Color
      final Text textWidget = tester.widget(labelText);
      expect(textWidget.style?.color, Colors.red);
    });

    testWidgets('Scenario 2: Zero balance displays "Settled" in Green', (
      WidgetTester tester,
    ) async {
      await pumpBottomAction(tester, balance: 0.0);

      final labelText = find.text('Settled');
      final amountText = find.text('₹0.00');

      expect(labelText, findsOneWidget);
      expect(amountText, findsOneWidget);

      // Verify Color
      final Text textWidget = tester.widget(labelText);
      expect(textWidget.style?.color, Colors.green);
    });

    testWidgets('Scenario 3: Negative balance displays "Settled" in Blue', (
      WidgetTester tester,
    ) async {
      await pumpBottomAction(tester, balance: -10.0);

      // Based on your code logic: balance > 0 ? 'Due' : 'Settled'
      expect(find.text('Settled'), findsOneWidget);
      expect(find.text('₹10.00'), findsOneWidget); // verify .abs() is working

      // Verify Color
      final Text textWidget = tester.widget(find.text('Settled'));
      expect(textWidget.style?.color, Colors.blue);
    });
  });

  group('Button State & Interaction Tests', () {
    testWidgets(
      'Scenario 4: Displays CircularProgressIndicator when processing',
      (WidgetTester tester) async {
        await pumpBottomAction(
          tester,
          balance: 0.0,
          isProcessing: true,
          canConfirm: true,
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('CONFIRM SALE'), findsNothing);
      },
    );

    testWidgets('Scenario 5: Button is disabled when canConfirm is false', (
      WidgetTester tester,
    ) async {
      bool wasPressed = false;
      await pumpBottomAction(
        tester,
        balance: 10.0,
        canConfirm: false,
        onConfirm: () => wasPressed = true,
      );

      final buttonFinder = find.byType(ElevatedButton);
      final ElevatedButton button = tester.widget(buttonFinder);

      // Verify button is disabled (onPressed is null)
      expect(button.enabled, isFalse);

      // Verify visual: background should be grey per code
      expect(button.style?.backgroundColor?.resolve({}), Colors.grey);

      // Tap and verify callback NOT called
      await tester.tap(buttonFinder);
      expect(wasPressed, isFalse);
    });

    testWidgets(
      'Scenario 6: Button is enabled and triggers callback when valid',
      (WidgetTester tester) async {
        bool wasPressed = false;
        await pumpBottomAction(
          tester,
          balance: 0.0,
          canConfirm: true,
          isProcessing: false,
          onConfirm: () => wasPressed = true,
        );

        final buttonFinder = find.byType(ElevatedButton);
        final ElevatedButton button = tester.widget(buttonFinder);

        expect(button.enabled, isTrue);
        expect(button.style?.backgroundColor?.resolve({}), Colors.green);

        // Tap and verify callback
        await tester.tap(buttonFinder);
        expect(wasPressed, isTrue);
      },
    );
  });
}
