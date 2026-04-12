import 'package:apoorva_app/enum/payment_mode.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/screens/sale_success/sale_success_screen.dart';
import 'package:apoorva_app/services/sale_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DailySalesHistoryScreen extends StatefulWidget {
  DateTime selectedDate;

  DailySalesHistoryScreen({
    super.key,
    DateTime? selectedDate, // 1. Make it nullable here
  }) : selectedDate = selectedDate ?? DateTime.now(); // 2. Assign if null

  @override
  State<DailySalesHistoryScreen> createState() =>
      _DailySalesHistoryScreenState();
}

class _DailySalesHistoryScreenState extends State<DailySalesHistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final organization = Provider.of<OrganizationProvider>(
      context,
    ).currentOrganization;

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
      body: (organization == null)
          ? CircularProgressIndicator()
          : StreamBuilder<List<Sale>>(
              // 1. Typed Stream using SaleService
              stream: SaleService().getSalesByDate(
                organization.id,
                widget.selectedDate,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Filter list based on search query
                final sales = snapshot.data!.where((sale) {
                  final name = sale.customerName.toLowerCase();
                  final id = sale.id.toLowerCase();
                  return name.contains(_searchQuery) ||
                      id.contains(_searchQuery);
                }).toList();

                if (sales.isEmpty) {
                  return const Center(
                    child: Text('No transactions found for this date.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index]; // Now a Sale object!

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ExpansionTile(
                        // 3. Using Enum and Model properties
                        leading: _buildPaymentStatusIcon(sale.payments),
                        title: Text(
                          '₹${sale.netPayable.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${sale.customerName} • ${DateFormat('hh:mm a').format(sale.timestamp)}',
                        ),
                        // trailing: _buildShareStatus(sale.whatsappStatus),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                _buildInfoRow('Full Bill ID', sale.id),
                                _buildInfoRow('Customer', sale.customerName),
                                _buildInfoRow(
                                  'Phone',
                                  sale.customerPhone.isEmpty
                                      ? 'No Phone Number'
                                      : sale.customerPhone,
                                ),
                                _buildInfoRow('Source', sale.source),
                                const SizedBox(height: 12),
                                const Text(
                                  'Items Purchased:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...sale.items.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '• ${item.categoryName} - ₹${item.finalPrice} (Qty: ${item.qty})',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _viewBill(sale, organization),
                                  icon: const Icon(Icons.layers_outlined),
                                  label: const Text('View Bill'),
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

  // UI Helpers updated for the model
  Widget _buildPaymentStatusIcon(Map<PaymentMode, double> payments) {
    // Determine the primary payment mode (the one with highest amount)
    final primaryMode = payments.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return CircleAvatar(
      backgroundColor: Colors.red.withOpacity(0.1),
      child: Icon(primaryMode.icon, color: Colors.red, size: 20),
    );
  }

  // --- ACTIONS ---

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => widget.selectedDate = picked);
  }

  void _viewBill(Sale sale, Organization organization) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SaleSuccessScreen(sale: sale, orgId: organization.id, canPop: true),
      ),
    );
  }
}
