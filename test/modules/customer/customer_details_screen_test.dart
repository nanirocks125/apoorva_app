import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/services/customer_service.dart';
import 'package:apoorva_app/services/sale_service.dart';
import 'package:apoorva_app/modules/customer/customer_details_screen.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// --- MOCKS ---
class MockCustomerService extends Mock implements CustomerService {}

class MockSaleService extends Mock implements SaleService {}

class MockOrganizationProvider extends Mock implements OrganizationProvider {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

class FakeLaunchOptions extends Fake implements LaunchOptions {}

class MockUrlLauncher extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

void main() {
  late MockCustomerService mockCustomerService;
  late MockSaleService mockSaleService;
  late MockOrganizationProvider mockOrgProvider;
  late MockUrlLauncher mockLauncher;

  final testCustomer = Customer(
    name: 'Manikanta',
    phone: '8121971462',
    totalSales: 5,
    totalAmountSpent: 5000.0,
    createdAt: DateTime(2025, 3, 23),
    lastPurchaseDate: DateTime(2026, 4, 10),
  );

  setUpAll(() {
    registerFallbackValue(testCustomer);
    registerFallbackValue(FakeRoute());
    registerFallbackValue(FakeLaunchOptions());
  });

  setUp(() {
    mockCustomerService = MockCustomerService();
    mockSaleService = MockSaleService();
    mockOrgProvider = MockOrganizationProvider();
    mockLauncher = MockUrlLauncher();

    // ✅ Define behavior here instead of in the class
    when(() => mockLauncher.canLaunch(any())).thenAnswer((_) async => true);
    when(
      () => mockLauncher.launchUrl(any(), any()),
    ).thenAnswer((_) async => true);

    UrlLauncherPlatform.instance = mockLauncher;

    // Default mock behavior
    when(() => mockOrgProvider.currentOrganization).thenReturn(
      Organization(
        id: 'org_123',
        name: 'Apoorva',
        createdAt: DateTime(2023, 1, 1),
      ),
    );
    when(
      () => mockSaleService.getCustomerSales(any(), any()),
    ).thenAnswer((_) => Stream.value([]));
  });

  Widget createWidget() {
    return ChangeNotifierProvider<OrganizationProvider>.value(
      value: mockOrgProvider,
      child: MaterialApp(
        // 1. Define a landing page so the Navigator has somewhere to 'pop' to
        home: const Scaffold(body: Text('Landing Page')),

        // 2. Define the route for the details screen
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => CustomerDetailsScreen(
              customer: testCustomer,
              customerService: mockCustomerService,
              saleService: mockSaleService,
            ),
          );
        },

        // 3. Start the test directly on the details screen
        initialRoute: '/details',
      ),
    );
  }

  group('CustomerDetailsScreen Tests', () {
    testWidgets('renders all profile data and tenure correctly', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Manikanta'), findsOneWidget);
      expect(find.text('8121971462'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('₹5000.0'), findsOneWidget);
      expect(find.textContaining('Customer for'), findsOneWidget);
      expect(find.text('23 Mar 2025'), findsOneWidget); // CreatedAt
    });

    testWidgets('tapping phone button launches dialer', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.byIcon(Icons.phone));
      await tester.pump();

      verify(() => mockLauncher.launchUrl('tel:8121971462', any())).called(1);
    });

    testWidgets('Deactivate menu action works correctly', (tester) async {
      when(
        () => mockCustomerService.toggleCustomerStatus(any(), any(), any()),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidget());

      // Open PopupMenu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deactivate'));
      await tester.pumpAndSettle();

      verify(
        () => mockCustomerService.toggleCustomerStatus(
          'org_123',
          '8121971462',
          false,
        ),
      ).called(1);
      expect(find.text('Customer deactivated'), findsOneWidget);
    });

    testWidgets('Delete Cancel button does not call service', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockCustomerService.deleteCustomer(any(), any()));
    });

    testWidgets('Delete Confirm button calls service and pops', (tester) async {
      when(
        () => mockCustomerService.deleteCustomer(any(), any()),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap the Red Delete button in the dialog
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      verify(
        () => mockCustomerService.deleteCustomer('org_123', '8121971462'),
      ).called(1);
    });

    testWidgets('Menu actions return early if organization is null', (
      tester,
    ) async {
      when(() => mockOrgProvider.currentOrganization).thenReturn(null);

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Deactivate'));
      await tester.pump();

      verifyNever(
        () => mockCustomerService.toggleCustomerStatus(any(), any(), any()),
      );
    });
  });
}
