import 'package:apoorva_app/components/category_form.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/services/inventory_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// 1. Define Fakes for Abstract/Complex classes
class FakeRoute extends Fake implements Route<dynamic> {}

class FakeCategory extends Fake implements Category {}

// 2. Define Mocks
class MockInventoryService extends Mock implements InventoryService {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockInventoryService mockService;
  late MockNavigatorObserver mockObserver;

  setUpAll(() {
    // 3. Register Fallbacks for all types used in any() or captureAny()
    registerFallbackValue(FakeRoute());
    registerFallbackValue(FakeCategory());
    registerFallbackValue(
      Category(
        id: '',
        name: '',
        currentStock: 0,
        isHotkey: true,
        billMachineNumber: 1,
      ),
    );
  });

  setUp(() {
    mockService = MockInventoryService();
    mockObserver = MockNavigatorObserver();
  });

  // Helper to wrap the widget
  Widget createWidgetUnderTest({Category? category}) {
    return MaterialApp(
      navigatorObservers: [mockObserver],
      home: Scaffold(
        body: CategoryForm(
          orgId: 'org123',
          category: category,
          inventoryService: mockService,
        ),
      ),
    );
  }

  group('CategoryForm Tests', () {
    testWidgets('Renders empty form for new category', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Inventory Category'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Category Name (e.g. Bangles)'),
        findsOneWidget,
      );
      expect(find.text(''), findsAtLeastNWidgets(2)); // Name and Stock empty
    });

    testWidgets('Populates fields when editing an existing category', (
      tester,
    ) async {
      final existing = Category(
        id: 'cat1',
        name: 'Gold',
        currentStock: 50,
        billMachineNumber: 5,
        isHotkey: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(category: existing));

      expect(find.text('Gold'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      // Check Switch state
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('Successfully saves category and navigates back', (
      tester,
    ) async {
      when(
        () => mockService.saveCategory(any(), any()),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter data
      await tester.enterText(find.byType(TextField).at(0), 'Silver');
      await tester.enterText(find.byType(TextField).at(1), '100');
      await tester.enterText(find.byType(TextField).at(2), '10');
      await tester.tap(find.byType(SwitchListTile));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      verify(() => mockService.saveCategory('org123', any())).called(1);
      verify(() => mockObserver.didPop(any(), any())).called(1);
    });

    testWidgets('Shows SnackBar on service error', (tester) async {
      when(
        () => mockService.saveCategory(any(), any()),
      ).thenThrow(Exception('Duplicate Name'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(find.byType(TextField).at(0), 'Error Case');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Start animation

      expect(find.text('Duplicate Name'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
      'Uses default values (0) when number fields are empty or invalid',
      (tester) async {
        when(
          () => mockService.saveCategory(any(), any()),
        ).thenAnswer((_) async => {});

        await tester.pumpWidget(createWidgetUnderTest());

        // Enter only name, leave numbers blank/invalid
        await tester.enterText(find.byType(TextField).at(0), 'Empty Numbers');
        await tester.enterText(
          find.byType(TextField).at(1),
          'abc',
        ); // Invalid stock

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Capture the saved category to verify defaults
        final savedCategory =
            verify(
                  () => mockService.saveCategory('org123', captureAny()),
                ).captured.first
                as Category;

        expect(savedCategory.currentStock, 0);
        expect(savedCategory.billMachineNumber, 0);
      },
    );
  });
}
