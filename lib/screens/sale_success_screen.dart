import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/model/whatsapp_script.dart';
import 'package:apoorva_app/providers/auth_provider.dart';
import 'package:apoorva_app/services/pdf_invoice_service.dart';
import 'package:apoorva_app/services/whatsapp_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SaleSuccessScreen extends StatelessWidget {
  final String orgId; // Add this line
  final Sale sale;

  const SaleSuccessScreen({super.key, required this.sale, required this.orgId});

  @override
  Widget build(BuildContext context) {
    // Calculate total discount (Item-level + Overall + Round-off)
    double totalItemSavings = 0.0;

    double itemTotalDiscounts = sale.items.fold(
      0.0,
      (sum, item) => sum + (item.stickerPrice - item.finalPrice),
    );
    double totalSavings =
        itemTotalDiscounts + sale.overallDiscountAmount + sale.roundOff;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevent going back to checkout
        title: const Text('Digital Receipt'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
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

            const Divider(height: 40),

            _buildSectionHeader('ITEMS'),
            ...sale.items.map((item) {
              double itemSaving = item.stickerPrice - item.finalPrice;
              totalItemSavings += itemSaving; // Summing up item-level savings

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
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
                    // Explicit Item Saving Row
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Saved: ₹${itemSaving.toStringAsFixed(2)} (${(item.discountPercent).toInt()}% Off)',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 32),

            // --- 2. UPDATED FINANCIAL SUMMARY ---
            _buildSectionHeader('FINANCIAL SUMMARY'),
            _receiptRow(
              'Cart Subtotal',
              '₹${sale.subtotal.toStringAsFixed(2)}',
            ),

            // Displaying the sum of item savings explicitly
            if (totalItemSavings > 0)
              _receiptRow(
                'Total Item Savings',
                '-₹${totalItemSavings.toStringAsFixed(2)}',
                color: Colors.green,
              ),

            if (sale.overallDiscountAmount > 0)
              _receiptRow(
                'Extra Overall Discount',
                '-₹${sale.overallDiscountAmount.toStringAsFixed(2)}',
                color: Colors.green,
              ),

            if (sale.roundOff > 0)
              _receiptRow(
                'Final Round-off',
                '-₹${sale.roundOff.toStringAsFixed(2)}',
                color: Colors.green,
              ),

            const Divider(height: 32),

            // --- 2. DISCOUNT & TAX SUMMARY ---
            _buildSectionHeader('FINANCIAL SUMMARY'),
            _receiptRow(
              'Cart Subtotal',
              '₹${sale.subtotal.toStringAsFixed(2)}',
            ),
            if (sale.overallDiscountAmount > 0)
              _receiptRow(
                'Overall Discount',
                '-₹${sale.overallDiscountAmount.toStringAsFixed(2)}',
                color: Colors.green,
              ),
            if (sale.roundOff > 0)
              _receiptRow(
                'Final Round-off',
                '-₹${sale.roundOff.toStringAsFixed(2)}',
                color: Colors.green,
              ),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _receiptRow(
                    'NET PAYABLE',
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

            const SizedBox(height: 32),

            // --- 3. PAYMENT BREAKDOWN (Tender Splitting) ---
            _buildSectionHeader('PAYMENT DETAILS'),
            ...sale.payments.entries
                .where((e) => e.value > 0)
                .map(
                  (e) => _receiptRow(
                    e.key.name, // Enum name (e.g., 'Cash', 'Card')
                    '₹${e.value.toStringAsFixed(2)}',
                    isBold: e.key == 'Cash',
                  ),
                ),

            const SizedBox(height: 48),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => PdfInvoiceService.createAndShareInvoice(
                customerName: sale.customerName,
                netPayable: sale.netPayable.toString(),
                saleId: sale.id,
                items: sale.items, // Pass your cart items list here
              ),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                'GENERATE & SHARE PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // ACTION BUTTONS
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // ఫోన్ నంబర్ లేకపోతే అలర్ట్ చూపండి
                if (sale.customerName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number not provided!')),
                  );
                  return;
                }
                // స్క్రిప్ట్ లైబ్రరీని ఓపెన్ చేయండి
                _openScriptLibrary(context, sale.customerPhone, sale);
              },
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                'SHARE VIA WHATSAPP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // This pops all screens (Success, Checkout, POS)
                // until it finds the route named '/home'
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
              child: const Text(
                'DONE - NEW SALE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF5733),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
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

  void _openScriptLibrary(BuildContext context, String phoneNumber, Sale sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select WhatsApp Script',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<WhatsAppScript>>(
                stream: WhatsAppService().getScriptsStream(orgId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  final scripts = snapshot.data ?? [];

                  return ListView.builder(
                    itemCount: scripts.length,
                    itemBuilder: (context, index) {
                      final script = scripts[index];
                      return ListTile(
                        title: Text(script.title),
                        subtitle: Text(script.language),
                        onTap: () {
                          // మోడల్ లో ఉన్న formatMessage ని వాడుకోవడం
                          final String message = script.formatMessage(sale);
                          WhatsAppService().launchWhatsApp(
                            phone: phoneNumber,
                            message: message,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
