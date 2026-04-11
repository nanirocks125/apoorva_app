import 'package:apoorva_app/enum/payment_mode.dart';
import 'package:apoorva_app/services/sale_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/model/sale_item.dart';

class CheckoutController extends ChangeNotifier {
  final PosCart cart;
  final Customer customer;
  final String orgId;
  final String? activeDraftId;

  CheckoutController({
    required this.cart,
    required this.customer,
    required this.orgId,
    this.activeDraftId,
  }) {
    // Initialize payment controllers and set default
    for (var mode in PaymentMode.values) {
      paymentControllers[mode] = TextEditingController();
    }
    paymentControllers[PaymentMode.cash]!.text = cart.totalPayable
        .toStringAsFixed(2);

    roundOffController.addListener(() {
      _autoSyncPayment(); // Synchronize the payment fields
      notifyListeners(); // Then notify the UI
    });
  }

  final TextEditingController roundOffController = TextEditingController(
    text: '0',
  );
  final Map<PaymentMode, bool> selectedModes = {PaymentMode.cash: true};
  final Map<PaymentMode, TextEditingController> paymentControllers = {};

  double _overallDiscountPercent = 0.0;
  bool _isProcessing = false;

  // Getters
  double get overallDiscountPercent => _overallDiscountPercent;
  bool get isProcessing => _isProcessing;
  double get overallDiscountAmount =>
      cart.totalPayable * (_overallDiscountPercent / 100);

  double get finalTotal {
    double roundOff = double.tryParse(roundOffController.text) ?? 0.0;
    return cart.totalPayable - overallDiscountAmount - roundOff;
  }

  double get totalPaid {
    return selectedModes.entries
        .where((e) => e.value)
        .map((e) => double.tryParse(paymentControllers[e.key]!.text) ?? 0.0)
        .fold(0, (prev, element) => prev + element);
  }

  double get balance => finalTotal - totalPaid;
  bool get isSettled => balance.abs() < 0.01;

  // Actions
  void setDiscount(double pct) {
    _overallDiscountPercent = pct;
    _autoSyncPayment();
    notifyListeners();
  }

  void togglePaymentMode(PaymentMode mode, bool isSelected) {
    selectedModes[mode] = isSelected;
    _autoSyncPayment();
    notifyListeners();
  }

  void _autoSyncPayment() {
    final active = selectedModes.entries.where((e) => e.value).toList();
    if (active.length == 1) {
      paymentControllers[active.first.key]!.text = finalTotal.toStringAsFixed(
        2,
      );
    }
  }

  Future<Sale?> finalizeSale() async {
    _isProcessing = true;
    notifyListeners();

    try {
      final payments = {
        for (var mode in selectedModes.keys)
          if (selectedModes[mode]!)
            mode: double.tryParse(paymentControllers[mode]!.text) ?? 0.0,
      };

      final saleItems = cart.items
          .map(
            (i) => SaleItem(
              categoryId: i.category.id,
              categoryName: i.category.name,
              qty: i.quantity,
              stickerPrice: i.mrp,
              finalPrice: i.finalPrice,
            ),
          )
          .toList();

      final String newSaleId = FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .collection('sales')
          .doc()
          .id;

      final sale = Sale(
        id: newSaleId,
        customerName: customer.name.isEmpty ? 'Walk-in' : customer.name,
        customerPhone: customer.phone,
        staffId: FirebaseAuth.instance.currentUser?.uid ?? 'System',
        items: saleItems,
        subtotal: cart.totalMRP,
        overallDiscountPercent: _overallDiscountPercent,
        overallDiscountAmount: overallDiscountAmount,
        roundOff: double.tryParse(roundOffController.text) ?? 0.0,
        netPayable: finalTotal,
        payments: payments,
        timestamp: DateTime.now(),
        source: 'POS',
        status: 'Completed',
      );

      await SaleService().confirmSaleWithAtomicCleanup(
        orgId,
        sale,
        activeDraftId,
      );
      return sale;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    roundOffController.dispose();
    for (var c in paymentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
