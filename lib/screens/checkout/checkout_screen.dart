import 'package:apoorva_app/enum/payment_mode.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/screens/checkout/bill_summary_card.dart';
import 'package:apoorva_app/screens/checkout/checkout_bottom_action.dart';
import 'package:apoorva_app/screens/checkout/checkout_controller.dart';
import 'package:apoorva_app/screens/checkout/customer_info_card.dart';
import 'package:apoorva_app/screens/checkout/discount_selector.dart';
import 'package:apoorva_app/screens/checkout/payment_method_tile.dart';
import 'package:apoorva_app/screens/sale_success/sale_success_screen.dart';
import 'package:flutter/material.dart';

class CheckoutScreen extends StatefulWidget {
  final PosCart cart;
  final Customer customer;
  final String orgId;
  final String? activeDraftId;
  final String? existingSaleId;
  final CheckoutController? controller; // Add this

  const CheckoutScreen({
    super.key,
    required this.cart,
    required this.customer,
    required this.orgId,
    this.activeDraftId,
    this.existingSaleId,
    this.controller, // Add this
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late CheckoutController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        CheckoutController(
          cart: widget.cart,
          customer: widget.customer,
          orgId: widget.orgId,
          activeDraftId: widget.activeDraftId,
          existingSaleId: widget.existingSaleId,
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(title: const Text('Finalize Payment')),
            body: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CUSTOMER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomerInfoCard(customer: widget.customer),

                  const SizedBox(height: 24),
                  const Text(
                    'DISCOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  DiscountSelector(
                    selectedPercent: _controller.overallDiscountPercent,
                    onSelect: _controller.setDiscount,
                  ),

                  const SizedBox(height: 24),
                  BillSummaryCard(
                    totalMrp: widget.cart.totalMRP,
                    totalDiscountOnMRP: widget.cart.totalDiscountOnMRP,
                    additionalDiscount: _controller
                        .overallDiscountAmount, // Placeholder - replace with actual additional discount if applicable
                    netTotal: _controller.finalTotal,
                    roundOffController: _controller.roundOffController,
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'PAYMENT METHODS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...PaymentMode.values.map(
                    (mode) => PaymentMethodTile(
                      mode: mode,
                      isSelected: _controller.selectedModes[mode] ?? false,
                      controller: _controller.paymentControllers[mode]!,
                      onToggle: (val) =>
                          _controller.togglePaymentMode(mode, val),
                      onChanged: () =>
                          setState(() {}), // Refresh balance display
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
            bottomNavigationBar: CheckoutBottomAction(
              balance: _controller.balance,
              isProcessing: _controller.isProcessing,
              canConfirm: _controller.isSettled,
              onConfirm: () async {
                final sale = await _controller.finalizeSale();
                if (sale != null && mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SaleSuccessScreen(
                        sale: sale,
                        orgId: widget.orgId,
                        canPop: false,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
