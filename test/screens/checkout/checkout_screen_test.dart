import 'package:apoorva_app/screens/checkout/checkout_bottom_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:apoorva_app/screens/checkout/checkout_screen.dart';
import 'package:apoorva_app/screens/checkout/checkout_controller.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/enum/payment_mode.dart';
import 'package:apoorva_app/screens/sale_success/sale_success_screen.dart';

// Mocks
class MockCheckoutController extends Mock
    with ChangeNotifier
    implements CheckoutController {}

class FakeSale extends Fake implements Sale {}

void main() {
  late MockCheckoutController mockController;
  late PosCart testCart;
  late Customer testCustomer;

  setUpAll(() {
    registerFallbackValue(FakeSale());
    registerFallbackValue(true);
  });

  setUp(() {
    mockController = MockCheckoutController();
    testCart = PosCart();
    testCustomer = Customer(
      name: 'John Doe',
      phone: '1234567890',
      createdAt: DateTime(2026, 1, 1),
      lastPurchaseDate: DateTime(2026, 1, 1),
    );

    // 1. Dynamically create controllers for ALL modes (including Store Credit)
    final allControllers = {
      for (var mode in PaymentMode.values)
        mode: TextEditingController(
          text: mode == PaymentMode.cash ? '1000.00' : '0.00',
        ),
    };

    final allSelected = {
      for (var mode in PaymentMode.values) mode: mode == PaymentMode.cash,
    };

    // 2. Stub the properties
    when(() => mockController.overallDiscountPercent).thenReturn(0.0);
    when(() => mockController.overallDiscountAmount).thenReturn(0.0);
    when(() => mockController.finalTotal).thenReturn(1000.0);
    when(() => mockController.balance).thenReturn(0.0);
    when(() => mockController.isProcessing).thenReturn(false);
    when(() => mockController.isSettled).thenReturn(true);

    // Use the complete maps here
    when(() => mockController.selectedModes).thenReturn(allSelected);
    when(() => mockController.paymentControllers).thenReturn(allControllers);
    when(
      () => mockController.roundOffController,
    ).thenReturn(TextEditingController(text: '0'));
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: CheckoutScreen(
        cart: testCart,
        customer: testCustomer,
        orgId: 'test_org',
        controller: mockController,
      ),
    );
  }

  group('CheckoutScreen Widget Tests', () {
    testWidgets('Initial Render: Should show all required components', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Finalize Payment'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget); // Customer Card
      expect(find.text('DISCOUNT'), findsOneWidget);
      expect(find.text('PAYMENT METHODS'), findsOneWidget);
      expect(find.text('CONFIRM SALE'), findsOneWidget);
    });

    testWidgets('Interaction: Tapping a discount chip calls controller', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Assuming DiscountSelector uses ChoiceChips with % labels
      final chip5 = find.text('5%');
      await tester.tap(chip5);
      await tester.pump();

      verify(() => mockController.setDiscount(5.0)).called(1);
    });

    testWidgets('Interaction: Toggling payment mode calls controller', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final upiTileFinder = find.text('UPI / PhonePe');

      // 1. Ensure the widget is scrolled into view before tapping
      await tester.ensureVisible(upiTileFinder);
      await tester.pumpAndSettle();

      // 2. Tap the tile
      await tester.tap(upiTileFinder);
      await tester.pump();

      // 3. Verify with any() matcher
      verify(
        () => mockController.togglePaymentMode(PaymentMode.upi, any()),
      ).called(1);
    });

    testWidgets('Validation: Confirm button is disabled when not settled', (
      tester,
    ) async {
      when(() => mockController.isSettled).thenReturn(false);
      when(() => mockController.balance).thenReturn(150.0);

      await tester.pumpWidget(createWidgetUnderTest());

      final button = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byType(CheckoutBottomAction),
          matching: find.byType(ElevatedButton),
        ),
      );

      expect(button.enabled, isFalse);
      expect(find.text('₹150.00'), findsOneWidget); // Balance due
    });

    testWidgets('Flow: Successful sale navigates to SaleSuccessScreen', (
      tester,
    ) async {
      final dummySale = Sale(
        id: '123',
        customerName: 'John Doe',
        customerPhone: '123',
        staffId: 'staff1',
        items: [],
        subtotal: 1000,
        netPayable: 1000,
        payments: {PaymentMode.cash: 1000},
        timestamp: DateTime.now(),
        source: 'POS',
        status: 'Completed',
        overallDiscountPercent: 0,
        overallDiscountAmount: 0,
        roundOff: 0,
      );

      when(
        () => mockController.finalizeSale(),
      ).thenAnswer((_) async => dummySale);
      when(() => mockController.isSettled).thenReturn(true);

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap and wait for the transition animation to finish
      await tester.tap(find.text('CONFIRM SALE'));
      await tester.pumpAndSettle();

      expect(find.byType(SaleSuccessScreen), findsOneWidget);
    });

    testWidgets('State: Shows loading indicator when processing', (
      tester,
    ) async {
      when(() => mockController.isProcessing).thenReturn(true);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('CONFIRM SALE'), findsNothing);
    });
  });

  testWidgets('should dismiss keyboard when dragging the scroll view', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // 1. Focus a field
    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    final FocusNode focusNode = FocusScope.of(
      tester.element(find.byType(TextField).first),
    ).focusedChild!;
    expect(focusNode.hasFocus, isTrue);

    // 2. Perform a drag/scroll gesture
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pump();

    // 3. Verify keyboard dismissed (due to ScrollViewKeyboardDismissBehavior.onDrag)
    expect(focusNode.hasFocus, isFalse);
  });
}
