import 'package:apoorva_app/modules/data_integrity/data_integrity_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/services/customer_service.dart';
import 'package:apoorva_app/services/sale_service.dart';

class MockCustomerService extends Mock implements CustomerService {}

class MockSaleService extends Mock implements SaleService {}

class MockOrganizationProvider extends Mock implements OrganizationProvider {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late MockCustomerService mockCustomerService;
  late MockSaleService mockSaleService;
  late MockOrganizationProvider mockOrgProvider;
  const orgId = 'apoorva_mangalagiri';

  setUpAll(() {
    // ✅ Use a Fake class for Route instead of the Type object
    registerFallbackValue(FakeRoute());
  });

  setUp(() {
    mockCustomerService = MockCustomerService();
    mockSaleService = MockSaleService();
    mockOrgProvider = MockOrganizationProvider();

    // ✅ Global Default Stubs: Prevents crashes when background tabs build
    when(() => mockOrgProvider.currentOrganization).thenReturn(
      Organization(id: orgId, name: 'Apoorva', createdAt: DateTime.now()),
    );
    when(
      () => mockCustomerService.getCustomers(any()),
    ).thenAnswer((_) => Stream.empty());
    when(
      () => mockSaleService.getCustomerSales(any(), any()),
    ).thenAnswer((_) => Stream.empty());
  });

  Widget createWidget() {
    return ChangeNotifierProvider<OrganizationProvider>.value(
      value: mockOrgProvider,
      child: MaterialApp(
        routes: {
          '/customer-details': (context) =>
              const Scaffold(body: Text('Details Page')),
        },
        home: DataIntegrityScreen(
          customerService: mockCustomerService,
          saleService: mockSaleService,
        ),
      ),
    );
  }

  group('DataIntegrityScreen - Audit Logic Tests', () {
    testWidgets('Tab 2: Identifies timeline paradox', (tester) async {
      final paradoxCustomer = Customer(
        name: 'Late Entry',
        phone: '8888888888',
        createdAt: DateTime(2026, 4, 10),
        lastPurchaseDate: DateTime(2026, 3, 28),
      );

      when(
        () => mockCustomerService.getCustomers(orgId),
      ).thenAnswer((_) => Stream.value([paradoxCustomer]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Timeline Errors'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Created date is after Last Purchase'),
        findsOneWidget,
      );
    });

    testWidgets('Tab 3: Identifies Balance Mismatches', (tester) async {
      final customer = Customer(
        name: 'Balance Error',
        phone: '7777777777',
        totalSales: 2,
        totalAmountSpent: 1000.0,
        createdAt: null,
        lastPurchaseDate: null,
      );

      final actualSales = [
        Sale(
          netPayable: 500.0,
          customerPhone: '7777777777',
          timestamp: DateTime.now(),
          id: 's1',
          staffId: '',
          customerName: '',
          items: [],
          subtotal: 500,
          overallDiscountPercent: 0,
          overallDiscountAmount: 0,
          roundOff: 0,
          payments: {},
          source: 'POS',
          status: 'Completed',
        ),
      ];

      when(
        () => mockCustomerService.getCustomers(orgId),
      ).thenAnswer((_) => Stream.value([customer]));
      when(
        () => mockSaleService.getCustomerSales(orgId, '7777777777'),
      ).thenAnswer((_) => Stream.value(actualSales));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Balance Mismatches'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Sales Count: DB(2) vs Actual(1)'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Total Spent: DB(₹1000.0) vs Actual(₹500.0)'),
        findsOneWidget,
      );
    });
  });
}
