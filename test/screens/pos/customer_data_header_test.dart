import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/screens/pos/customer_data_header.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/services/customer_service.dart';

class MockPosProvider extends Mock implements PosProvider {}

class MockCustomerService extends Mock
    implements CustomerService {} // 🟢 మాక్ సర్వీస్

void main() {
  late MockPosProvider mockProvider;
  late MockCustomerService mockCustomerService;
  late TextEditingController nameController;
  late TextEditingController phoneController;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const MethodChannel(
      'plugins.flutter.io/firebase_core',
    ).setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'initializeApp') {
        return {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': '123',
            'appId': '123',
            'messagingSenderId': '123',
            'projectId': '123',
          },
          'pluginConstants': {},
        };
      }
      return null;
    });
  });

  setUp(() {
    mockProvider = MockPosProvider();
    mockCustomerService = MockCustomerService();
    nameController = TextEditingController();
    phoneController = TextEditingController();

    when(() => mockProvider.nameController).thenReturn(nameController);
    when(() => mockProvider.phoneController).thenReturn(phoneController);
    when(() => mockProvider.orgId).thenReturn('apoorva_mangalagiri');
  });

  // 🟢 హెల్పర్: మాక్ సర్వీస్ ని విజెట్ కి ఇంజెక్ట్ చేయడం
  Widget createWidgetUnderTest({Stream<List<Customer>>? customerStream}) {
    final stream = customerStream ?? Stream.value([]);
    when(
      () => mockCustomerService.getCustomers(any()),
    ).thenAnswer((_) => stream);

    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<PosProvider>.value(
          value: mockProvider,
          child: CustomerDataHeader(
            customerService: mockCustomerService,
          ), // 🟢 ఇంజెక్ట్ చేసాం
        ),
      ),
    );
  }

  group('CustomerDataHeader Widget & Local Search Tests', () {
    testWidgets('Should render both TextFields with correct hints and icons', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Customer Name'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
    });

    testWidgets('Entering text in UI should update the Provider controllers', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.enterText(
        find.widgetWithText(TextField, 'Customer Name'),
        'Manikanta',
      );
      expect(nameController.text, 'Manikanta');
    });

    testWidgets(
      'Typing less than 3 characters should not show search overlay',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.enterText(
          find.widgetWithText(TextField, 'Customer Name'),
          'Kr',
        );
        await tester.pump();
        expect(find.byType(ListTile), findsNothing);
      },
    );

    testWidgets(
      'Typing 3+ characters should trigger search and display overlay if matches exist',
      (tester) async {
        final mockCustomers = [
          Customer(
            name: 'Krishna',
            phone: '9247192396',
            lastPurchaseDate: DateTime.now(),
          ),
          Customer(
            name: 'Manikanta',
            phone: '8121971462',
            lastPurchaseDate: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          createWidgetUnderTest(customerStream: Stream.value(mockCustomers)),
        );
        await tester.pump();

        await tester.enterText(
          find.widgetWithText(TextField, 'Customer Name'),
          'kri',
        );
        await tester.pump();

        expect(find.text('Krishna'), findsOneWidget);
        expect(find.text('9247192396'), findsOneWidget);
        expect(find.text('Manikanta'), findsNothing);
      },
    );

    testWidgets(
      'Tapping a search result should populate fields and close overlay',
      (tester) async {
        final mockCustomers = [
          Customer(
            name: 'Krishna',
            phone: '9247192396',
            lastPurchaseDate: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          createWidgetUnderTest(customerStream: Stream.value(mockCustomers)),
        );
        await tester.pump();

        await tester.enterText(
          find.widgetWithText(TextField, 'Customer Name'),
          'Kris',
        );
        await tester.pump();

        await tester.tap(find.text('Krishna'));
        await tester.pump();

        expect(nameController.text, 'Krishna');
        expect(phoneController.text, '9247192396');
        expect(find.byType(ListView), findsNothing);
      },
    );
  });
}
