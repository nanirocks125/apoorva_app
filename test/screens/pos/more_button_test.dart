import 'package:apoorva_app/screens/pos/more_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoreButton Widget Tests', () {
    testWidgets('Should render correct icon and text', (tester) async {
      // 1. Widget ని లోడ్ చేయడం
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MoreButton(onTap: () {})),
        ),
      );

      // 2. Icon ఉందో లేదో వెతకడం
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

      // 3. 'More' అనే టెక్స్ట్ ఉందో లేదో వెతకడం
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('Should trigger onTap when clicked', (tester) async {
      bool tapped = false;

      // 1. Widget ని లోడ్ చేయడం
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MoreButton(onTap: () => tapped = true)),
        ),
      );

      // 2. InkWell మీద క్లిక్ చేయడం
      await tester.tap(find.byType(InkWell));

      // 3. స్టేట్ అప్‌డేట్ అయ్యే వరకు వెయిట్ చేయడం
      await tester.pump();

      // 4. Assertion
      expect(tapped, true);
    });

    testWidgets('Should have correct width and decoration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MoreButton(onTap: () {})),
        ),
      );

      // Container ని వెతకడం
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;

      // కన్స్ట్రైంట్స్ వెరిఫై చేయడం
      expect(container.constraints?.maxWidth, 100);
      expect(decoration.borderRadius, BorderRadius.circular(16));
      expect(decoration.color, Colors.grey.shade100);
    });
  });
}
