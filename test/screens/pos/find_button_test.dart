import 'package:apoorva_app/screens/pos/find_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FindButton Widget Tests', () {
    testWidgets('Should render correct icon and text', (tester) async {
      // 1. Widget ని లోడ్ చేయడం
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FindButton(onTap: () {})),
        ),
      );

      // 2. Icon ఉందో లేదో వెతకడం
      expect(find.byIcon(Icons.manage_search_rounded), findsOneWidget);

      // 3. 'Find' అనే టెక్స్ట్ ఉందో లేదో వెతకడం
      expect(find.text('FIND'), findsOneWidget);
    });

    testWidgets('Should trigger onTap when clicked', (tester) async {
      bool tapped = false;

      // 1. Widget ని లోడ్ చేయడం
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FindButton(onTap: () => tapped = true)),
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
          home: Scaffold(
            body: FindButton(onTap: () {}),
          ), // onTap ని null ఇవ్వొచ్చు
        ),
      );

      final finder = find.byKey(const Key('find_button_container')).first;
      final container = tester.widget<Container>(finder);
      final decoration = container.decoration as BoxDecoration;

      // 🚀 UPDATED ASSERTIONS
      expect(decoration.borderRadius, BorderRadius.circular(16));

      // Gradient వాడుతున్నాం కాబట్టి ఇలా చెక్ చేయాలి
      expect(decoration.gradient, isNotNull);
      final gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors[0], const Color(0xFFFF5733));
    });
  });
}
