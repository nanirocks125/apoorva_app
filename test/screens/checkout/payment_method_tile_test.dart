import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/enum/payment_mode.dart';
import 'package:apoorva_app/screens/checkout/payment_method_tile.dart';

void main() {
  late TextEditingController testController;

  setUp(() {
    testController = TextEditingController();
  });

  tearDown(() {
    testController.dispose();
  });

  Widget createWidgetUnderTest({
    required PaymentMode mode,
    required bool isSelected,
    required Function(bool) onToggle,
    required VoidCallback onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PaymentMethodTile(
          mode: mode,
          isSelected: isSelected,
          controller: testController,
          onToggle: onToggle,
          onChanged: onChanged,
        ),
      ),
    );
  }

  group('PaymentMethodTile Widget Tests', () {
    testWidgets(
      'Scenario 1: Should show only CheckboxListTile when NOT selected',
      (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            mode: PaymentMode.cash,
            isSelected: false,
            onToggle: (_) {},
            onChanged: () {},
          ),
        );

        // Verify Title exists
        expect(find.text(PaymentMode.cash.displayName), findsOneWidget);

        // Verify Checkbox value
        final checkbox = tester.widget<CheckboxListTile>(
          find.byType(CheckboxListTile),
        );
        expect(checkbox.value, isFalse);

        // Verify TextField is HIDDEN
        expect(find.byType(TextField), findsNothing);

        // Verify Border Color is Grey
        final container = tester.widget<Container>(find.byType(Container));
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border?.top.color, Colors.grey.shade200);
      },
    );

    testWidgets('Scenario 2: Should show TextField when selected', (
      tester,
    ) async {
      testController.text = '500.00';

      await tester.pumpWidget(
        createWidgetUnderTest(
          mode: PaymentMode.upi,
          isSelected: true,
          onToggle: (_) {},
          onChanged: () {},
        ),
      );

      // Verify Checkbox value
      final checkbox = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkbox.value, isTrue);

      // Verify TextField is VISIBLE and has correct value
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('500.00'), findsOneWidget);
      expect(find.text('₹ '), findsOneWidget); // Prefix check

      // Verify Border Color is Green
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border?.top.color, Colors.green);
    });

    testWidgets('Scenario 3: Tapping the tile triggers onToggle', (
      tester,
    ) async {
      bool? toggledVal;

      await tester.pumpWidget(
        createWidgetUnderTest(
          mode: PaymentMode.card,
          isSelected: false,
          onToggle: (val) => toggledVal = val,
          onChanged: () {},
        ),
      );

      // Tap the List Tile
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();

      expect(toggledVal, isTrue);
    });

    testWidgets('Scenario 4: Typing in TextField triggers onChanged', (
      tester,
    ) async {
      bool changeTriggered = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          mode: PaymentMode.cash,
          isSelected: true,
          onToggle: (_) {},
          onChanged: () => changeTriggered = true,
        ),
      );

      // Enter text into the field
      await tester.enterText(find.byType(TextField), '100');
      await tester.pump();

      expect(changeTriggered, isTrue);
      expect(testController.text, '100');
    });

    testWidgets('Scenario 5: Verify Keyboard Type is numeric', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          mode: PaymentMode.cash,
          isSelected: true,
          onToggle: (_) {},
          onChanged: () {},
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.number);
    });
  });
}
