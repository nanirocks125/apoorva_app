import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/screens/checkout/discount_selector.dart';

void main() {
  // Helper to wrap the widget in a MaterialApp
  Widget createWidgetUnderTest({
    required double selectedPercent,
    required Function(double) onSelect,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DiscountSelector(
          selectedPercent: selectedPercent,
          onSelect: onSelect,
        ),
      ),
    );
  }

  group('DiscountSelector Widget Tests', () {
    testWidgets(
      'should render all five discount options (0%, 5%, 10%, 15%, 20%)',
      (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(selectedPercent: 0.0, onSelect: (_) {}),
        );

        expect(find.text('0%'), findsOneWidget);
        expect(find.text('5%'), findsOneWidget);
        expect(find.text('10%'), findsOneWidget);
        expect(find.text('15%'), findsOneWidget);
        expect(find.text('20%'), findsOneWidget);

        // Verify exactly 5 chips are present
        expect(find.byType(ChoiceChip), findsNWidgets(5));
      },
    );

    testWidgets(
      'should show the correct chip as selected based on selectedPercent',
      (tester) async {
        const selectedValue = 10.0;
        await tester.pumpWidget(
          createWidgetUnderTest(
            selectedPercent: selectedValue,
            onSelect: (_) {},
          ),
        );

        // Find the ChoiceChip widget for 10%
        final ChoiceChip chip = tester.widget(
          find.widgetWithText(ChoiceChip, '10%'),
        );
        final ChoiceChip otherChip = tester.widget(
          find.widgetWithText(ChoiceChip, '0%'),
        );

        expect(chip.selected, isTrue);
        expect(otherChip.selected, isFalse);
      },
    );

    testWidgets(
      'should trigger onSelect with correct value when a chip is tapped',
      (tester) async {
        double? capturedValue;

        await tester.pumpWidget(
          createWidgetUnderTest(
            selectedPercent: 0.0,
            onSelect: (val) => capturedValue = val,
          ),
        );

        // Tap the 15% chip
        await tester.tap(find.text('15%'));
        await tester.pump();

        expect(capturedValue, 15.0);
      },
    );

    testWidgets(
      'should not trigger onSelect when tapping an already selected chip',
      (tester) async {
        int callCount = 0;

        await tester.pumpWidget(
          createWidgetUnderTest(
            selectedPercent: 10.0,
            onSelect: (_) => callCount++,
          ),
        );

        // Tap the 10% chip again
        // ChoiceChip onSelected returns false if tapping an already selected chip
        await tester.tap(find.text('10%'));
        await tester.pump();

        // Based on current logic: (val) => val ? onSelect(pct) : null
        // callCount should not increase because 'val' would be false
        expect(callCount, 0);
      },
    );

    testWidgets('should verify Wrap layout properties', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(selectedPercent: 0.0, onSelect: (_) {}),
      );

      final Wrap wrap = tester.widget(find.byType(Wrap));
      expect(wrap.spacing, 8.0);
    });
  });
}
