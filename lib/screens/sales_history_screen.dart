import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SalesHistoryScreen extends StatefulWidget {
  final String orgId;

  const SalesHistoryScreen({super.key, required this.orgId});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Audit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search Bill ID or Customer...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Scoped to the organization and sorted by time for Cash Integrity
        stream: FirebaseFirestore.instance
            .collection('organizations')
            .doc(widget.orgId)
            .collection('sales')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          // Client-side filtering for high-speed search across the daily list
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['customerName'] ?? '').toString().toLowerCase();
            final id = doc.id.toLowerCase();
            return name.contains(_searchQuery) || id.contains(_searchQuery);
          }).toList();

          if (docs.isEmpty)
            return const Center(child: Text('No transactions found.'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final sale = docs[index].data() as Map<String, dynamic>;
              final String saleId = docs[index].id;
              final DateTime date = (sale['timestamp'] as Timestamp).toDate();

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ExpansionTile(
                  leading: _buildPaymentIcon(sale['paymentMode'] ?? 'Cash'),
                  title: Text(
                    '₹${sale['netPayable']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${sale['customerName']} • ${DateFormat('hh:mm a').format(date)}',
                  ),
                  trailing: _buildShareStatus(
                    sale['whatsapp_status'] ?? 'unsent',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          _buildInfoRow('Full Bill ID', saleId),
                          _buildInfoRow(
                            'Payment Mode',
                            sale['paymentMode'] ?? 'Cash',
                          ),
                          _buildInfoRow(
                            'Date',
                            DateFormat('dd MMM yyyy').format(date),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Items Purchased:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...(sale['items'] as List? ?? [])
                              .map(
                                (item) => Text(
                                  '• ${item['name']} (₹${item['price']})',
                                ),
                              )
                              .toList(),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _reshareBill(saleId, sale),
                                icon: const Icon(Icons.share),
                                label: const Text('Reshare'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _printBill(saleId, sale),
                                icon: const Icon(Icons.print),
                                label: const Text('Print PDF'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildPaymentIcon(String mode) {
    return CircleAvatar(
      backgroundColor: mode == 'UPI'
          ? Colors.purple.shade50
          : Colors.green.shade50,
      child: Icon(
        mode == 'UPI' ? Icons.phonelink_ring : Icons.payments_outlined,
        color: mode == 'UPI' ? Colors.purple : Colors.green,
        size: 20,
      ),
    );
  }

  Widget _buildShareStatus(String status) {
    bool isSent = status == 'sent';
    return Icon(
      isSent ? Icons.check_circle : Icons.error_outline,
      color: isSent ? Colors.green : Colors.redAccent,
      size: 18,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- ACTIONS ---

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _reshareBill(String id, Map<String, dynamic> data) {
    // Navigates back to the Script Library to reshare
  }

  void _printBill(String id, Map<String, dynamic> data) {
    // Logic to regenerate the PDF Receipt
  }
}
