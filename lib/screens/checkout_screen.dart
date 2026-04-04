import 'package:apoorva_app/enum/payment_mode.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/model/sale_item.dart';
import 'package:apoorva_app/screens/sale_success_screen.dart';
import 'package:apoorva_app/services/sale_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';

class CheckoutScreen extends StatefulWidget {
  final PosCart cart;
  final String orgId;
  final Customer customer;
  final String? activeDraftId; // NEW: To handle draft deletion

  const CheckoutScreen({
    super.key,
    required this.cart,
    required this.orgId,
    required this.customer,
    this.activeDraftId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _discountController = TextEditingController(text: '0');
  final _discountFocusNode = FocusNode();

  // Payment State
  final Map<PaymentMode, bool> _selectedModes = {
    PaymentMode.cash: true,
    PaymentMode.upi: false,
    PaymentMode.card: false,
  };
  final Map<PaymentMode, TextEditingController> _paymentControllers = {
    PaymentMode.cash: TextEditingController(),
    PaymentMode.upi: TextEditingController(),
    PaymentMode.card: TextEditingController(),
  };

  final Map<PaymentMode, FocusNode> _paymentFocusNodes = {
    PaymentMode.cash: FocusNode(),
    PaymentMode.upi: FocusNode(),
    PaymentMode.card: FocusNode(),
  };

  bool _isProcessing = false;

  double get _balance {
    return _finalTotal - _totalPaid;
  }

  String get _balanceLabel {
    if (_balance > 0) return 'Balance Due (Debt)';
    if (_balance < 0) return 'Customer Credit';
    return 'Settled';
  }

  Color get _balanceColor {
    if (_balance > 0) return Colors.red; // Debt is a warning
    if (_balance < 0) return Colors.blue; // Credit is a liability/promise
    return Colors.green; // Perfectly matched
  }

  double _overallDiscountPercent = 0.0; // New state for % discount

  double get _overallDiscountAmount {
    return widget.cart.totalPayable * (_overallDiscountPercent / 100);
  }

  @override
  void initState() {
    super.initState();

    _discountController.addListener(_syncDefaultPayment);
    _syncDefaultPayment();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _discountFocusNode.dispose();
    for (var node in _paymentFocusNodes.values) {
      node.dispose();
    }
    for (var controller in _paymentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncDefaultPayment() {
    if (_isProcessing) return;

    // We only auto-sync if the user hasn't started a complex split payment
    // Or simply, we update the 'Cash' field whenever the total changes
    setState(() {
      _paymentControllers[PaymentMode.cash]!.text = _finalTotal.toStringAsFixed(
        2,
      );
    });
  }

  double get _finalTotal {
    double roundOff = double.tryParse(_discountController.text) ?? 0.0;

    // Logic: Original - Percentage - Round-off
    return widget.cart.totalPayable - _overallDiscountAmount - roundOff;
  }

  double get _totalPaid {
    double sum = 0;
    _selectedModes.forEach((mode, isSelected) {
      if (isSelected) {
        sum += double.tryParse(_paymentControllers[mode]!.text) ?? 0.0;
      }
    });
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Only unfocus when tapping the background, not widgets
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finalize Payment'),
          backgroundColor: const Color(0xFFFF5733),
        ),
        body: SingleChildScrollView(
          // Prevent scroll from dismissing keyboard automatically
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('CUSTOMER DETAILS'),
              _buildCustomerInfoCard(),
              const SizedBox(height: 24),

              // if (kDebugMode) _buildSectionHeader('OVERALL DISCOUNT (%)'),
              // if (kDebugMode) _buildDiscountChips(),
              // if (kDebugMode) const SizedBox(height: 24),
              _buildCartItemsList(),
              const SizedBox(height: 24),

              _buildSectionHeader('BILL SUMMARY'),
              _buildBillSummaryCard(),

              const SizedBox(height: 30),

              _buildSectionHeader('COLLECT PAYMENT'),
              // Use .values or .entries and provide a ValueKey
              ..._selectedModes.keys.map((mode) => _buildPaymentRow(mode)),

              const SizedBox(height: 40),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomAction(),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.customer.name.isEmpty
                ? 'Walk-in Customer'
                : widget.customer.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.customer.phone.isEmpty
                ? 'No Phone Provided'
                : widget.customer.phone,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildBillSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _summaryRow(
            'Cart Subtotal',
            '₹${widget.cart.totalPayable.toStringAsFixed(2)}',
          ),
          if (_overallDiscountPercent > 0)
            _summaryRow(
              'Flat ${_overallDiscountPercent.toInt()}% Discount',
              '- ₹${_overallDiscountAmount.toStringAsFixed(2)}',
              color: Colors.green.shade700,
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Final Round-off',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _discountController,
                  focusNode: _discountFocusNode,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    setState(() {});
                    _syncDefaultPayment(); // Manual trigger
                  },
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32, thickness: 1),
          _summaryRow(
            'NET PAYABLE',
            '₹${_finalTotal.toStringAsFixed(2)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(PaymentMode mode) {
    bool isSelected = _selectedModes[mode]!;

    return AnimatedContainer(
      key: ValueKey(mode), // CRITICAL: Keeps the widget identity stable
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.grey.shade50,
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            title: Text(
              mode.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            value: isSelected,
            activeColor: Colors.green,
            onChanged: (val) {
              setState(() {
                _selectedModes[mode] = val!;
                if (!val) _paymentControllers[mode]!.clear();
              });
              _syncDefaultPayment();
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 8),
              child: TextField(
                controller: _paymentControllers[mode],
                focusNode: _paymentFocusNodes[mode], // Explicitly assigned
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Amount for ${mode.displayName}',
                  prefixText: '₹ ',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    // Now we only check if the sale is valid (Net total > 0)
    bool canPay = _finalTotal > 0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_balance != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '$_balanceLabel: ₹${_balance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: _balanceColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              backgroundColor: canPay ? Colors.green : Colors.grey,
            ),
            onPressed: canPay && !_isProcessing ? _finalizeSale : null,
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'CONFIRM SALE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Update the % Discount selection to trigger the sync
  Widget _buildDiscountChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [0.0, 5.0, 10.0, 15.0, 20.0].map((pct) {
        return ChoiceChip(
          label: Text('${pct.toInt()}%'),
          selected: _overallDiscountPercent == pct,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _overallDiscountPercent = pct;
                // Trigger sync after the % discount changes
                _syncDefaultPayment();
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeSale() async {
    setState(() => _isProcessing = true);

    // 1. Collect Payments using Enum
    Map<PaymentMode, double> payments = {};
    _selectedModes.forEach((mode, isSelected) {
      if (isSelected) {
        payments[mode] =
            double.tryParse(_paymentControllers[mode]!.text) ?? 0.0;
      }
    });

    try {
      // 2. Map CartItems to SaleItems (The serialized model)
      final saleItems = widget.cart.items
          .map(
            (i) => SaleItem(
              categoryId: i.category.id,
              categoryName: i.category.name,
              qty: 1, // Change if you support multiple quantities
              stickerPrice: i.mrp,
              finalPrice: i.finalPrice,
            ),
          )
          .toList();

      // 3. Pre-generate ID to keep ID == DocID consistent
      final String newSaleId = FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.orgId)
          .collection('sales')
          .doc()
          .id;

      // 4. Create the Sale Model Object
      final newSale = Sale(
        id: newSaleId,
        customerName: widget.customer.name.isEmpty
            ? 'Walk-in'
            : widget.customer.name,
        customerPhone: widget.customer.phone,
        staffId: FirebaseAuth.instance.currentUser?.uid ?? 'Unknown',
        items: saleItems,
        subtotal: widget.cart.totalPayable,
        overallDiscountPercent: _overallDiscountPercent,
        overallDiscountAmount: _overallDiscountAmount,
        roundOff: double.tryParse(_discountController.text) ?? 0.0,
        netPayable: _finalTotal,
        payments: payments,
        timestamp: DateTime.now(),
        source: 'POS', // Or detect from widget
        status: 'Completed',
      );

      // 5. Execute Atomic Transaction
      await SaleService().confirmSaleWithAtomicCleanup(
        widget.orgId,
        newSale,
        widget.activeDraftId,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SaleSuccessScreen(
              sale: newSale,
              orgId: widget.orgId,
            ), // Just pass the whole object!
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sale Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildCartItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('CART ITEMS'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // Important inside SingleChildScrollView
            itemCount: widget.cart.items.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade50),
            itemBuilder: (context, index) {
              final item = widget.cart.items[index];
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.category.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          Text(
                            '₹${item.mrp.toStringAsFixed(0)} - ${item.discountPercent.toInt()}%',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${item.finalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
