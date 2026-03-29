import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SaleSuccessScreen extends StatelessWidget {
  final String orgId; // Add this line
  final String saleId;
  final String customerPhone;
  final String customerName;
  final List<dynamic> items; // List of items sold
  final double subtotal;
  final double overallDiscountAmount;
  final double roundOff;
  final double netPayable;
  final Map<String, double> payments;

  const SaleSuccessScreen({
    super.key,
    required this.saleId,
    required this.customerPhone,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.overallDiscountAmount,
    required this.roundOff,
    required this.netPayable,
    required this.payments,
    required this.orgId,
  });

  Map<String, dynamic> get _saleSummaryData => {
    'id': saleId,
    'customerName': customerName,
    'netPayable': netPayable,
  };

  @override
  Widget build(BuildContext context) {
    // Calculate total discount (Item-level + Overall + Round-off)
    double totalItemSavings = 0.0;

    double itemTotalDiscounts = items.fold(
      0.0,
      (sum, item) => sum + (item['stickerPrice'] - item['finalPrice']),
    );
    double totalSavings = itemTotalDiscounts + overallDiscountAmount + roundOff;

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
              'ID: $saleId',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),

            const Divider(height: 40),

            _buildSectionHeader('ITEMS'),
            ...items.map((item) {
              double itemSaving = item['stickerPrice'] - item['finalPrice'];
              totalItemSavings += itemSaving; // Summing up item-level savings

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item['name']} (₹${item['stickerPrice'].toStringAsFixed(0)})',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '₹${item['finalPrice'].toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    // Explicit Item Saving Row
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Saved: ₹${itemSaving.toStringAsFixed(2)} (${(item['itemDiscountPercent'] ?? 0).toInt()}% Off)',
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
            _receiptRow('Cart Subtotal', '₹${subtotal.toStringAsFixed(2)}'),

            // Displaying the sum of item savings explicitly
            if (totalItemSavings > 0)
              _receiptRow(
                'Total Item Savings',
                '-₹${totalItemSavings.toStringAsFixed(2)}',
                color: Colors.green,
              ),

            if (overallDiscountAmount > 0)
              _receiptRow(
                'Extra Overall Discount',
                '-₹${overallDiscountAmount.toStringAsFixed(2)}',
                color: Colors.green,
              ),

            if (roundOff > 0)
              _receiptRow(
                'Final Round-off',
                '-₹${roundOff.toStringAsFixed(2)}',
                color: Colors.green,
              ),

            const Divider(height: 32),

            // --- 2. DISCOUNT & TAX SUMMARY ---
            _buildSectionHeader('FINANCIAL SUMMARY'),
            _receiptRow('Cart Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
            if (overallDiscountAmount > 0)
              _receiptRow(
                'Overall Discount',
                '-₹${overallDiscountAmount.toStringAsFixed(2)}',
                color: Colors.green,
              ),
            if (roundOff > 0)
              _receiptRow(
                'Final Round-off',
                '-₹${roundOff.toStringAsFixed(2)}',
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
                    '₹${netPayable.toStringAsFixed(2)}',
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
            ...payments.entries
                .where((e) => e.value > 0)
                .map(
                  (e) => _receiptRow(
                    e.key,
                    '₹${e.value.toStringAsFixed(2)}',
                    isBold: e.key == 'Cash',
                  ),
                ),

            const SizedBox(height: 48),

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
                if (customerPhone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number not provided!')),
                  );
                  return;
                }
                // స్క్రిప్ట్ లైబ్రరీని ఓపెన్ చేయండి
                _openScriptLibrary(context, customerPhone, _saleSummaryData);
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
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
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

  void _openScriptLibrary(
    BuildContext context,
    String phoneNumber,
    Map<String, dynamic> saleData,
  ) {
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
              child: StreamBuilder<QuerySnapshot>(
                // Fetching scripts from the organization's library
                stream: FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(orgId)
                    .collection('scripts')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final scripts = snapshot.data!.docs;
                  if (scripts.isEmpty) {
                    return const Center(
                      child: Text(
                        'No scripts available.\nPlease add some in Admin settings.',
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: scripts.length,
                    itemBuilder: (context, index) {
                      final script =
                          scripts[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(script['title']),
                        subtitle: Text(
                          script['language'],
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(
                          Icons.send,
                          color: Color(0xFF25D366),
                        ),
                        onTap: () => _sendWhatsAppMessage(
                          phoneNumber,
                          script['content'],
                          saleData,
                        ),
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

  Future<void> _sendWhatsAppMessage(
    String phone,
    String template,
    Map<String, dynamic> data,
  ) async {
    // Processing placeholders for a personalized touch
    String message = template
        .replaceAll('[NAME]', data['customerName'] ?? 'Customer')
        .replaceAll('[AMOUNT]', '₹${data['netPayable']}')
        .replaceAll('[ID]', data['id']);

    // Add Apoorva brand footer or care instructions as required by PRD
    message +=
        "\n\nCare Tip: Keep your jewelry away from perfumes to maintain its shine! ✨"; //

    final encodedMessage = Uri.encodeComponent(message);
    final url = "https://wa.me/$phone?text=$encodedMessage";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
