import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/screens/pos/customer_data_header.dart'; // పాత్ సరిచూడండి
import 'package:apoorva_app/screens/pos/pos_provider.dart';

// 1. Mock PosProvider
class MockPosProvider extends Mock implements PosProvider {}

void main() {
  late MockPosProvider mockProvider;
  late TextEditingController nameController;
  late TextEditingController phoneController;

  setUp(() {
    mockProvider = MockPosProvider();
    nameController = TextEditingController();
    phoneController = TextEditingController();

    // Provider లోని కంట్రోలర్స్ ని మాక్ చేయడం
    when(() => mockProvider.nameController).thenReturn(nameController);
    when(() => mockProvider.phoneController).thenReturn(phoneController);
    when(() => mockProvider.orgId).thenReturn('apoorva_mangalagiri');
  });

  // Helper function
  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<PosProvider>.value(
          value: mockProvider,
          child: const CustomerDataHeader(),
        ),
      ),
    );
  }

  group('CustomerDataHeader Widget Tests', () {
    testWidgets('Should render both TextFields with correct hints and icons', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Hints వెతకడం
      expect(find.text('Customer Name'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);

      // Icons వెతకడం
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.phone_iphone_outlined), findsOneWidget);
    });

    testWidgets('Entering text in UI should update the Provider controllers', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Name ఎంటర్ చేయడం
      await tester.enterText(
        find.widgetWithText(TextField, 'Customer Name'),
        'Manikanta',
      );
      expect(nameController.text, 'Manikanta');

      // 2. Phone ఎంటర్ చేయడం
      await tester.enterText(
        find.widgetWithText(TextField, 'Phone'),
        '9876543210',
      );
      expect(phoneController.text, '9876543210');
    });

    testWidgets('Pre-filled values in controllers should show up in UI', (
      tester,
    ) async {
      // కంట్రోలర్ లో ముందే డేటా ఉంటే (ఉదా: Resume Draft చేసినప్పుడు)
      nameController.text = 'Apoorva Client';
      phoneController.text = '1234567890';

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Apoorva Client'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
    });
  });
}
