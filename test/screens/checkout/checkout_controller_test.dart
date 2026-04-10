import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:apoorva_app/enum/payment_mode.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/screens/checkout/checkout_controller.dart';
import 'package:apoorva_app/services/sale_service.dart';

class MockSaleService extends Mock implements SaleService {}

class FakeSale extends Fake implements Sale {}

void main() {
  late CheckoutController controller;
  late PosCart cart;
  late MockSaleService mockSaleService;
  const String orgId = 'test_org';

  setUpAll(() {
    registerFallbackValue(FakeSale());
  });

  setUp(() {
    mockSaleService = MockSaleService();

    // Setup Cart with 1000 total (600 + 400)
    cart = PosCart();
    cart.items = [
      CartItem(
        category: Category(
          id: '1',
          name: 'Item 1',
          currentStock: 0,
          isHotkey: false,
          billMachineNumber: 0,
        ),
        mrp: 600.0,
        discountPercent: 0.0,
      ),
      CartItem(
        category: Category(
          id: '2',
          name: 'Item 2',
          currentStock: 0,
          isHotkey: false,
          billMachineNumber: 0,
        ),
        mrp: 500.0,
        discountPercent: 20.0, // Result: 400
      ),
    ];

    controller = CheckoutController(
      cart: cart,
      customer: Customer(
        name: 'John Doe',
        phone: '999',
        createdAt: DateTime(2026, 1, 1),
        lastPurchaseDate: DateTime(2026, 1, 1),
      ),
      orgId: orgId,
    );
  });

  group('1. Initialization Scenarios', () {
    test('should initialize with correct totals and default cash payment', () {
      expect(controller.finalTotal, 1000.0);
      expect(controller.isProcessing, false);
      expect(controller.selectedModes[PaymentMode.cash], true);
      expect(controller.paymentControllers[PaymentMode.cash]!.text, '1000.00');
    });
  });

  group('2. Discount & Round-off Scenarios', () {
    test('setDiscount should update net total and sync payment field', () {
      controller.setDiscount(10.0); // 10% of 1000 = 100

      expect(controller.overallDiscountAmount, 100.0);
      expect(controller.finalTotal, 900.0);
      // Auto-sync check
      expect(controller.paymentControllers[PaymentMode.cash]!.text, '900.00');
    });

    test('updating round-off should update finalTotal and payment field', () {
      controller.roundOffController.text = '5.50';

      // 1000 - 5.50 = 994.50
      expect(controller.finalTotal, 994.50);
      expect(controller.paymentControllers[PaymentMode.cash]!.text, '994.50');
    });
  });

  group('3. Payment Mode & Split Scenarios', () {
    test('toggling a new mode should not overwrite existing splits', () {
      controller.togglePaymentMode(PaymentMode.upi, true);

      // Manually set a split
      controller.paymentControllers[PaymentMode.cash]!.text = '700.00';
      controller.paymentControllers[PaymentMode.upi]!.text = '300.00';

      expect(controller.totalPaid, 1000.0);
      expect(controller.balance, 0.0);
      expect(controller.isSettled, true);
    });

    test('balance should reflect underpayment correctly', () {
      controller.paymentControllers[PaymentMode.cash]!.text = '850.00';
      expect(controller.balance, 150.0);
      expect(controller.isSettled, false);
    });

    test('isSettled should handle tiny double precision differences', () {
      controller.paymentControllers[PaymentMode.cash]!.text = '1000.0001';
      expect(controller.isSettled, true);
    });
  });

  test('dispose should not throw errors', () {
    controller.dispose();
  });
}
