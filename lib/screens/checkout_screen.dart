import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';

class CheckoutScreen extends StatefulWidget {
  final PosCart cart;
  final String orgId;
  final String customerName; // Pass these from PosScreen
  final String customerPhone;

  const CheckoutScreen({
    super.key,
    required this.cart,
    required this.orgId,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _discountController = TextEditingController(text: '0');

  // Payment State
  final Map<String, bool> _selectedModes = {
    'Cash': true,
    'UPI': false,
    'Card': false,
  };
  final Map<String, TextEditingController> _paymentControllers = {
    'Cash': TextEditingController(),
    'UPI': TextEditingController(),
    'Card': TextEditingController(),
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

  @override
  void initState() {
    super.initState();
    // Default cash to the full total on load
    _paymentControllers['Cash']!.text = widget.cart.totalPayable
        .toStringAsFixed(2);
  }

  double get _finalTotal {
    double discount = double.tryParse(_discountController.text) ?? 0.0;
    return widget.cart.totalPayable - discount;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalize Payment'),
        backgroundColor: const Color(0xFFFF5733),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. READ-ONLY CUSTOMER SECTION ---
            _buildSectionHeader('CUSTOMER DETAILS'),
            Container(
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
                    widget.customerName.isEmpty
                        ? 'Walk-in Customer'
                        : widget.customerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.customerPhone.isEmpty
                        ? 'No Phone Provided'
                        : widget.customerPhone,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 2. MULTI-PAYMENT SECTION ---
            _buildSectionHeader('PAYMENT MODES (SPLIT ALLOWED)'),
            ..._selectedModes.keys.map((mode) => _buildPaymentRow(mode)),

            const SizedBox(height: 24),

            // --- 3. SETTLEMENT SUMMARY ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    'Cart Subtotal',
                    '₹${widget.cart.totalPayable.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Final Round-off Discount'),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _discountController,
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            prefixText: '₹ ',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _summaryRow(
                    'NET PAYABLE',
                    '₹${_finalTotal.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                  _summaryRow(
                    'TOTAL ENTERED',
                    '₹${_totalPaid.toStringAsFixed(2)}',
                    color: _totalPaid == _finalTotal
                        ? Colors.green
                        : Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildPaymentRow(String mode) {
    bool isSelected = _selectedModes[mode]!;
    return AnimatedContainer(
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
              mode,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            value: isSelected,
            activeColor: Colors.green,
            onChanged: (val) => setState(() => _selectedModes[mode] = val!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 8),
              child: TextField(
                controller: _paymentControllers[mode],
                keyboardType: TextInputType.number,
                autofocus: mode == 'Cash',
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Amount for $mode',
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

  // Finalize Sale logic (Include both the discount and the payment breakdown)
  Future<void> _finalizeSale() async {
    // ... Batch logic here ...
  }
}
