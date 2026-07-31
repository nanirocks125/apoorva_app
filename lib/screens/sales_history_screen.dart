// widgets/customer_sales_history.dart
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/services/sale_service.dart';
import 'package:apoorva_app/screens/sale_success/sale_success_screen.dart'; // Adjust import
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CustomerSalesHistory extends StatelessWidget {
  final String customerPhone;
  SaleService _salesService;

  CustomerSalesHistory({
    super.key,
    required this.customerPhone,
    SaleService? service,
  }) : _salesService = service ?? SaleService();

  @override
  Widget build(BuildContext context) {
    final organization = Provider.of<OrganizationProvider>(
      context,
    ).currentOrganization;
    return StreamBuilder<List<Sale>>(
      stream: _salesService.getCustomerSales(
        organization?.id ?? '',
        customerPhone,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
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
            final sale = sales[index];
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/customer-details',
                  arguments: sale.timestamp,
                );
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.teal),
                  title: Text(
                    '₹${sale.netPayable.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy').format(sale.timestamp),
                  ),
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
                          const SizedBox(height: 8),
                          const Text(
                            'Items:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...sale.items.map(
                            (item) => Text(
                              '• ${item.categoryName} (₹${item.finalPrice})',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SaleSuccessScreen(
                                    sale: sale,
                                    orgId: organization?.id ?? '',
                                    canPop: true,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.receipt),
                              label: const Text('View Full Bill'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
}
