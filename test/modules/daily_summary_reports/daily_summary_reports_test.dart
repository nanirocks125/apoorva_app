import 'dart:async';
import 'package:apoorva_app/modules/daily-summary-report/daily_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/modules/daily-summary-report/daily_summary_report.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/services/sale_service.dart';
import 'package:apoorva_app/model/organization/organization.dart';

// --- Mocks ---
class MockOrganizationProvider extends Mock implements OrganizationProvider {}

class MockSaleService extends Mock implements SaleService {}

void main() {
  late MockOrganizationProvider mockOrgProvider;
  late MockSaleService mockSaleService;
  late StreamController<List<DailySummary>> streamController;

  const testOrgId = 'org_123';
  final testOrg = Organization(
    id: testOrgId,
    name: 'Apoorva Jewelry',
    createdAt: DateTime(2023, 2, 1),
  );

  setUp(() {
    mockOrgProvider = MockOrganizationProvider();
    mockSaleService = MockSaleService();
    streamController = StreamController<List<DailySummary>>();

    // Default mock behavior
    when(() => mockOrgProvider.currentOrganization).thenReturn(testOrg);
    when(
      () => mockSaleService.getDailySummaries(
        any(),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) => streamController.stream);
  });

  tearDown(() {
    streamController.close();
  });

  // Helper to pump the widget with necessary providers
  Future<void> pumpSummaryScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OrganizationProvider>.value(
            value: mockOrgProvider,
          ),
          // SaleService removed from here because it's passed via constructor
        ],
        child: MaterialApp(
          // Remove 'const' here and pass the mock service
          home: SalesSummaryScreen(saleService: mockSaleService),
        ),
      ),
    );
  }

  group('SalesSummaryScreen Initial States', () {
    testWidgets('shows "No Organization available" when organization is null', (
      tester,
    ) async {
      when(() => mockOrgProvider.currentOrganization).thenReturn(null);
      await pumpSummaryScreen(tester);
      expect(find.text('No Organization available'), findsOneWidget);
    });

    testWidgets('shows loading indicator when stream is waiting', (
      tester,
    ) async {
      await pumpSummaryScreen(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when stream has error', (tester) async {
      await pumpSummaryScreen(tester);
      streamController.addError('Database Error');
      await tester.pump();
      expect(find.text('Error loading data'), findsOneWidget);
    });
  });

  group('Data Display & Logic', () {
    testWidgets('correctly aggregates and displays data from stream', (
      tester,
    ) async {
      final mockData = [
        DailySummary(
          date: DateTime(2026, 4, 10),
          totalAmount: 5000.0,
          saleCount: 5,
        ),
        DailySummary(
          date: DateTime(2026, 4, 9),
          totalAmount: 3000.0,
          saleCount: 2,
        ),
      ];

      await pumpSummaryScreen(tester);
      streamController.add(mockData);
      await tester.pumpAndSettle();

      // Check Grand Total: 5000 + 3000 = 8000
      // formatCurrency uses locale en_IN, so verify formatted string
      expect(find.textContaining('8,000.00'), findsOneWidget);
      expect(find.text('Reporting over 2 Days'), findsOneWidget);

      // Check specific list cards
      expect(find.text('Friday'), findsOneWidget); // Apr 10, 2026
      expect(find.text('5 transactions'), findsOneWidget);
      expect(find.textContaining('5,000.00'), findsOneWidget);
    });
  });

  group('Filter Functionality', () {
    testWidgets('opens Date Range Picker when calendar icon is tapped', (
      tester,
    ) async {
      await pumpSummaryScreen(tester);

      // Tap the calendar icon
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));

      // Rebuild the widget to show the dialog.
      // Dialogs take time to animate in.
      await tester.pump(const Duration(seconds: 1));

      // ✅ FIX 1: Find by Type (Most robust way)
      expect(find.byType(DateRangePickerDialog), findsOneWidget);

      // ✅ FIX 2: If you want to check text, use case-insensitive RegExp
      // Material 3 usually uses "Select range"
      expect(
        find.textContaining(RegExp(r'Select range', caseSensitive: false)),
        findsOneWidget,
      );
    });
    testWidgets('shows Filter Chip and clears it when "X" is tapped', (
      tester,
    ) async {
      await pumpSummaryScreen(tester);

      // 1. CRITICAL: The StreamBuilder starts in 'waiting' state (showing a loader).
      // Provide data to the stream so the builder renders the CustomScrollView.
      streamController.add([]);
      await tester
          .pumpAndSettle(); // Wait for the loader to disappear and UI to render

      // 2. Get the state instance
      final state = tester.state<SalesSummaryScreenState>(
        find.byType(SalesSummaryScreen),
      );

      // 3. Update the state
      state.setState(() {
        state.selectedRange = DateTimeRange(
          start: DateTime(2026, 4, 1),
          end: DateTime(2026, 4, 5),
        );
      });

      // 4. Rebuild the widget tree to show the Chip
      await tester.pump();

      // Verify the Chip appeared
      expect(find.byType(Chip), findsOneWidget);

      // 5. Tap the 'X' (close icon)
      await tester.tap(find.byIcon(Icons.close));

      // 6. Rebuild to reflect the onDeleted logic
      await tester.pump();

      // Verify it's gone
      expect(find.byType(Chip), findsNothing);
    });
  });

  group('Edge Cases', () {
    testWidgets('handles empty list gracefully', (tester) async {
      await pumpSummaryScreen(tester);
      streamController.add([]);
      await tester.pumpAndSettle();

      expect(find.textContaining('0.00'), findsOneWidget);
      expect(find.text('Reporting over 0 Days'), findsOneWidget);
    });

    testWidgets('FittedBox scales large revenue text without crashing', (
      tester,
    ) async {
      await pumpSummaryScreen(tester);

      final largeAmount = 999999999.99;

      streamController.add([
        DailySummary(
          date: DateTime.now(),
          totalAmount: largeAmount,
          saleCount: 1,
        ),
      ]);

      await tester.pumpAndSettle();

      // 1. Verify the FittedBox itself exists
      expect(find.byType(FittedBox), findsOneWidget);

      // 2. FIX: Find the Text widget that is a child of the FittedBox
      // This ignores the text inside the daily card
      final headerText = find.descendant(
        of: find.byType(FittedBox),
        matching: find.textContaining('99,99,99,999.99'),
      );

      expect(headerText, findsOneWidget);

      // Optional: Verify the style is the "Large" header style (weight 900)
      Text textWidget = tester.widget(headerText);
      expect(textWidget.style?.fontWeight, FontWeight.w900);
    });
  });
}
