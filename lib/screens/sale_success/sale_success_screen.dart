import 'package:apoorva_app/services/bluetooth_thermal_printer_service.dart';
import 'package:apoorva_app/services/invoice_document_sharing_service.dart';
import 'package:apoorva_app/services/printer_service.dart';
import 'package:apoorva_app/services/receipt_communication_service.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SaleSuccessScreen extends StatelessWidget {
  final String orgId;
  final Sale sale;

  const SaleSuccessScreen({super.key, required this.sale, required this.orgId});

  @override
  Widget build(BuildContext context) {
    // 1. Calculate the values based on Checkout logic
    final double totalMrp = sale.items.fold(
      0.0,
      (sum, item) => sum + item.stickerPrice,
    );
    final double itemDiscounts = sale.items.fold(
      0.0,
      (sum, item) => sum + (item.stickerPrice - item.finalPrice),
    );

    // Subtotal = Total MRP - Item Discounts
    final double subtotal = totalMrp - itemDiscounts;

    // Bill Amount = Subtotal - Additional Discount
    final double billAmount = subtotal - sale.overallDiscountAmount;

    // Total Savings logic for the blue box
    final double totalSavings =
        itemDiscounts + sale.overallDiscountAmount + sale.roundOff;

    return PopScope(
      canPop: false, // This disables the swipe back and back button
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Optional: You could trigger the same logic as your "Done" button here
        // or simply do nothing to keep the user on this screen.
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Digital Receipt'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              // Use the same navigation logic as your 'Done' button
              // to ensure the stack is cleared properly.
              final loggedInUser = Provider.of<AuthProvider>(
                context,
                listen: false,
              ).user;

              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
                arguments: loggedInUser,
              );
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildSuccessHeader(),
              const Divider(height: 40),
              _buildItemsSection(),
              const Divider(height: 32),
              // Updated Financial Summary passing new values
              _buildFinancialSummary(
                totalMrp: totalMrp,
                itemDiscounts: itemDiscounts,
                subtotal: subtotal,
                billAmount: billAmount,
                totalSavings: totalSavings,
              ),
              const Divider(height: 32),
              _buildPaymentDetails(),
              const SizedBox(height: 40),
              _buildActionButtons(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Sub-Sections ---

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
          'Sale Successful!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          'ID: ${sale.id}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ITEMS'),
        ...sale.items.map((item) {
          double itemSaving = item.stickerPrice - item.finalPrice;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.categoryName} (₹${item.stickerPrice.toStringAsFixed(0)})',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '₹${item.finalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (itemSaving > 0)
                  Text(
                    'Saved: ₹${itemSaving.toStringAsFixed(2)} (${item.discountPercent.toInt()}% Off)',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFinancialSummary({
    required double totalMrp,
    required double itemDiscounts,
    required double subtotal,
    required double billAmount,
    required double totalSavings,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('FINANCIAL SUMMARY'),

        _receiptRow('Total MRP', '₹${totalMrp.toStringAsFixed(2)}'),

        if (itemDiscounts > 0)
          _receiptRow(
            'Item Discounts',
            '-₹${itemDiscounts.toStringAsFixed(2)}',
            color: Colors.green,
          ),

        if (sale.overallDiscountAmount > 0) const Divider(),
        if (sale.overallDiscountAmount > 0)
          _receiptRow(
            'Subtotal',
            '₹${subtotal.toStringAsFixed(2)}',
            isBold: true,
          ),

        if (sale.overallDiscountAmount > 0)
          _receiptRow(
            'Additional Discount',
            '-₹${sale.overallDiscountAmount.toStringAsFixed(2)}',
            color: Colors.green,
          ),
        if (sale.overallDiscountAmount > 0) const Divider(),

        _receiptRow('Bill Amount', '₹${billAmount.toStringAsFixed(2)}'),

        if (sale.roundOff != 0)
          _receiptRow(
            'Round-off',
            '-₹${sale.roundOff.toStringAsFixed(2)}', // Matches your "23.08" screenshot logic
            color: Colors.green,
          ),

        if (sale.roundOff != 0) const Divider(),
        if (sale.roundOff != 0)
          _receiptRow(
            'Net Payment Amount',
            '₹${sale.netPayable.toStringAsFixed(2)}',
            isBold: true,
          ),

        const SizedBox(height: 12),

        if (sale.roundOff > 0 || sale.overallDiscountAmount > 0)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _receiptRow(
                  'Total MRP',
                  '₹${totalMrp.toStringAsFixed(2)}',
                  isBold: true,
                ),
                _receiptRow(
                  'Total Bill Amount',
                  '₹${sale.netPayable.toStringAsFixed(2)}',
                  isBold: true,
                ),
                _receiptRow(
                  'YOU SAVED',
                  '₹${totalSavings.toStringAsFixed(2)}',
                  color: Colors.blue,
                  isBold: true,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('PAYMENT DETAILS'),
        ...sale.payments.entries
            .where((e) => e.value > 0)
            .map(
              (e) => _receiptRow(
                e.key.name.toUpperCase(),
                '₹${e.value.toStringAsFixed(2)}',
              ),
            ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _actionButton(
          icon: Icons.print,
          label: 'Print Receipt',
          color: Colors.blueGrey,
          onPressed: () => BluetoothThermalPrinterService()
              .printReceiptViaBluetooth(context, sale),
        ),
        _actionButton(
          icon: Icons.message,
          label: 'Send Text Message',
          color: Colors.blueGrey,
          onPressed: () =>
              ReceiptCommunicationService().sendTextMessage(context, sale),
        ),
        // _actionButton(
        //   icon: Icons.picture_as_pdf,
        //   label: 'Generate & Share PDF',
        //   color: Colors.blueGrey,
        //   onPressed: () => PrinterService().printReceipt(context, sale),
        // ),
        _actionButton(
          icon: Icons.share,
          label: 'Share WhatsApp Message',
          color: const Color(0xFF25D366),
          onPressed: () =>
              ReceiptCommunicationService().sendWhatsAppTextOnly(context, sale),
        ),
        // _actionButton(
        //   icon: Icons.attach_file,
        //   label: 'Share PDF on WhatsApp',
        //   color: const Color(0xFF25D366),
        //   onPressed: () => InvoiceDocumentSharingService().sendInvoiceDocument(
        //     context,
        //     sale,
        //     sale.id,
        //   ),
        // ),
      ],
    );
  }

  // --- Helper Methods ---

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size.fromHeight(55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _receiptRow(
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
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
