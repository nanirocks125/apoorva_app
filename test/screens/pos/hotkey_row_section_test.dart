import 'dart:async';
import 'package:apoorva_app/screens/pos/category_card.dart';
import 'package:apoorva_app/screens/pos/hot_key_row_section.dart';
import 'package:apoorva_app/screens/pos/find_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:apoorva_app/model/category/category.dart';

// Mocks
class MockPosProvider extends Mock implements PosProvider {}

class MockOrganizationService extends Mock implements OrganizationService {}

void main() {
  late MockPosProvider mockProvider;
  late MockOrganizationService mockService;
  late Completer<List<Category>> completer;

  setUp(() {
    mockProvider = MockPosProvider();
    mockService = MockOrganizationService();
    completer = Completer<List<Category>>();

    when(() => mockProvider.orgId).thenReturn('apoorva_mangalagiri');
  });

  Widget createWidgetUnderTest({Future<List<Category>> Function()? fetcher}) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<PosProvider>.value(
          value: mockProvider,
          child: CustomScrollView(
            slivers: [
              HotkeyRowSection(
                service: mockService,
                categoriesFetcher:
                    fetcher, // 🟢 పాస్ చేసిన ఫెచర్ ని ఇక్కడ బైండ్ చేస్తున్నాం
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('HotkeyRowSection Tests', () {
    testWidgets('Should show loading or nothing when future has no data yet', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          fetcher: () =>
              completer.future, // ఇంకా కంప్లీట్ కాని ఫ్యూచర్ పంపుతున్నాం
        ),
      );

      // Loading indicator లేదా కంటెంట్ రాకముందు స్టేట్ చెక్
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Should only show categories where isHotkey is true', (
      tester,
    ) async {
      final categories = [
        Category(
          id: '1',
          name: 'Hotkey Item',
          currentStock: 10,
          isHotkey: true,
          billMachineNumber: 1,
        ),
        Category(
          id: '2',
          name: 'Normal Item',
          currentStock: 5,
          isHotkey: false,
          billMachineNumber: 1,
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(fetcher: () async => categories),
      );

      await tester.pumpAndSettle(); // Future పూర్తి అయ్యే వరకు వేచి చూస్తుంది

      // Hotkey ఉన్న వస్తువు మాత్రమే కనిపించాలి
      expect(find.text('Hotkey Item'), findsOneWidget);
      expect(find.text('Normal Item'), findsNothing);

      // 'More' button కచ్చితంగా ఉండాలి
      expect(find.byType(FindButton), findsOneWidget);
    });

    testWidgets('Should render correct number of hotkey cards', (tester) async {
      final categories = [
        Category(
          id: '1',
          name: 'Cat 1',
          currentStock: 10,
          isHotkey: true,
          billMachineNumber: 1,
        ),
        Category(
          id: '2',
          name: 'Cat 2',
          currentStock: 5,
          isHotkey: true,
          billMachineNumber: 1,
        ),
      ];

      await tester.pumpWidget(
        createWidgetUnderTest(fetcher: () async => categories),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CategoryCard), findsNWidgets(2));
    });
  });
}
