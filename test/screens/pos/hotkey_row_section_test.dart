import 'dart:async';
import 'package:apoorva_app/screens/pos/category_card.dart';
import 'package:apoorva_app/screens/pos/hot_key_row_section.dart';
import 'package:apoorva_app/screens/pos/more_button.dart';
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
  late StreamController<List<Category>> streamController;

  setUp(() {
    mockProvider = MockPosProvider();
    mockService = MockOrganizationService();
    streamController = StreamController<List<Category>>();

    when(() => mockProvider.orgId).thenReturn('apoorva_mangalagiri');
  });

  tearDown(() async {
    await streamController.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<PosProvider>.value(
          value: mockProvider,
          child: CustomScrollView(
            slivers: [
              HotkeyRowSection(service: mockService), // Inject Mock Service
            ],
          ),
        ),
      ),
    );
  }

  group('HotkeyRowSection Tests', () {
    testWidgets('Should show nothing when stream has no data', (tester) async {
      when(
        () => mockService.getLiveCategories(any()),
      ).thenAnswer((_) => streamController.stream);

      await tester.pumpWidget(createWidgetUnderTest());
      // No data added to stream yet

      expect(find.byType(CategoryCard), findsNothing);
      expect(find.byType(MoreButton), findsNothing);
    });

    testWidgets('Should only show categories where isHotkey is true', (
      tester,
    ) async {
      when(
        () => mockService.getLiveCategories(any()),
      ).thenAnswer((_) => streamController.stream);

      await tester.pumpWidget(createWidgetUnderTest());

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

      streamController.add(categories);
      await tester.pump();

      // Hotkey ఉన్న వస్తువు మాత్రమే కనిపించాలి
      expect(find.text('Hotkey Item'), findsOneWidget);
      expect(find.text('Normal Item'), findsNothing);

      // 'More' button కచ్చితంగా ఉండాలి
      expect(find.byType(MoreButton), findsOneWidget);
    });

    testWidgets('Should render correct number of hotkey cards', (tester) async {
      when(
        () => mockService.getLiveCategories(any()),
      ).thenAnswer((_) => streamController.stream);

      await tester.pumpWidget(createWidgetUnderTest());

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

      streamController.add(categories);
      await tester.pump();

      expect(find.byType(CategoryCard), findsNWidgets(2));
    });
  });
}
