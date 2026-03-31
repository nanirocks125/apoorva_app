import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/services/sale_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CustomerHistoryScreen extends StatelessWidget {
  final String orgId;
  final Customer customer;

  const CustomerHistoryScreen({
    super.key,
    required this.orgId,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${customer.name}\'s Purchases')),
      body: StreamBuilder<List<Sale>>(
        // 1. Typed Stream using SaleService
        stream: SaleService().getCustomerSales(orgId, customer.phone),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Error fetching sales: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sales = snapshot.data ?? [];

          if (sales.isEmpty) {
            return const Center(child: Text('No purchase history found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index]; // Now a Sale object!

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.teal),
                  title: Text(
                    '₹${sale.netPayable.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(sale.timestamp),
                  ),
                  trailing: _buildStatusBadge(sale.whatsappStatus),
                  children: [
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Bill ID:', sale.id.substring(0, 8)),
                          _buildDetailRow(
                            'Discount:',
                            '₹${sale.overallDiscountAmount}',
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Items Purchased:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          // SaleItem మోడల్ నుండి ఐటెమ్స్ మ్యాపింగ్
                          ...sale.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '• ${item.categoryId} (₹${item.finalPrice})',
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Existing PDF logic with sale object
                              },
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('View/Share Bill'),
                            ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isSent = status == 'sent';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSent
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isSent ? 'SENT' : 'NOT SHARED',
        style: TextStyle(
          color: isSent ? Colors.green : Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
