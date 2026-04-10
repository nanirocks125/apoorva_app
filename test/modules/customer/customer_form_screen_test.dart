import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/services/customer_service.dart';
import 'package:apoorva_app/modules/customer/customer_form_screen.dart';
import 'package:intl/intl.dart';

// Mocking the service
class MockCustomerService extends Mock implements CustomerService {}

void main() {
  late MockCustomerService mockService;
  const orgId = 'test_org';

  setUpAll(() {
    // Register fallback for Customer model so mocktail understands the type
    registerFallbackValue(
      Customer(
        name: '',
        phone: '',
        createdAt: DateTime.now(),
        lastPurchaseDate: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockService = MockCustomerService();
  });

  // Helper to wrap widget with necessary parents
  Widget createWidget({Customer? existingCustomer}) {
    return MaterialApp(
      // 1. Define a landing page for when the form pops
      home: const Scaffold(body: Text('Landing Page')),

      // 2. Define the route for the form
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => CustomerFormScreen(
            orgId: orgId,
            existingCustomer: existingCustomer,
            customerService: mockService,
          ),
        );
      },

      // 3. Start the test directly on the form route
      initialRoute: '/form',
    );
  }

  group('CustomerFormScreen - UI & Logic Tests', () {
    testWidgets('renders Create mode correctly', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('New Customer'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Phone should be enabled
      final phoneField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Phone Number'),
      );
      expect(phoneField.enabled, isTrue);
    });

    testWidgets('renders Edit mode with existing data', (tester) async {
      final existing = Customer(
        name: 'Manikanta',
        phone: '1234567890',
        createdAt: DateTime(2025, 1, 1),
        lastPurchaseDate: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(createWidget(existingCustomer: existing));

      expect(find.text('Edit Customer'), findsOneWidget);
      expect(find.text('Manikanta'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
      expect(
        find.textContaining('Phone number cannot be changed'),
        findsOneWidget,
      );

      // Phone should be disabled
      final phoneField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Phone Number'),
      );
      expect(phoneField.enabled, isFalse);
    });

    testWidgets('shows validation errors for empty fields', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Enter valid phone'), findsOneWidget);
      verifyNever(() => mockService.saveCustomer(any(), any()));
    });

    testWidgets('picks a new "Customer Since" date', (tester) async {
      await tester.pumpWidget(createWidget());

      // Tap the first date picker (Customer Since)
      await tester.tap(
        find.text(DateFormat('dd MMM yyyy').format(DateTime.now())),
      );
      await tester.pumpAndSettle();

      // Pick the 1st day of current month in the picker
      await tester.tap(find.text('1'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Verify UI updated (Checking for '01' as day)
      expect(find.textContaining('01 '), findsOneWidget);
    });

    testWidgets('sets and clears "Last Purchase Date"', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Not set (No purchases yet)'), findsOneWidget);

      // Tap to pick date
      await tester.tap(find.text('Not set (No purchases yet)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Not set (No purchases yet)'), findsNothing);

      // Clear the date
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(find.text('Not set (No purchases yet)'), findsOneWidget);
    });

    testWidgets('successful save navigates back and shows snackbar', (
      tester,
    ) async {
      // ✅ FIX 2: Add a delay so the loading spinner actually renders for a frame
      when(() => mockService.saveCustomer(any(), any())).thenAnswer(
        (_) async => Future.delayed(const Duration(milliseconds: 100)),
      );

      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'Suresh',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone Number'),
        '9988776655',
      );

      await tester.tap(find.byType(ElevatedButton));

      // Pump a frame to trigger the rebuild after _isLoading = true
      await tester.pump();

      // Now the spinner will be found
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the 100ms delay and the navigation to finish
      await tester.pumpAndSettle();

      verify(() => mockService.saveCustomer(orgId, any())).called(1);
      expect(find.text('Customer saved successfully!'), findsOneWidget);
    });

    testWidgets('successful save navigates back and shows snackbar', (
      tester,
    ) async {
      // ✅ FIX 2: Add delay for the loading spinner frame
      when(() => mockService.saveCustomer(any(), any())).thenAnswer(
        (_) async => Future.delayed(const Duration(milliseconds: 100)),
      );

      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        'Suresh',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone Number'),
        '9988776655',
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(); // Frame 1: Show Loading

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // ✅ FIX 3: pumpAndSettle waits for the 100ms, the Pop, AND the SnackBar animation
      await tester.pumpAndSettle();

      verify(() => mockService.saveCustomer(orgId, any())).called(1);

      // Verify we landed back on the landing page
      expect(find.text('Landing Page'), findsOneWidget);

      // Verify SnackBar is visible on the landing page
      expect(find.text('Customer saved successfully!'), findsOneWidget);
    });
  });
}
