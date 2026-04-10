// screens/customer_details_screen.dart
import 'package:apoorva_app/modules/customer/customer_form_screen.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/screens/sales_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/services/customer_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // ✅ Don't forget to import this for date formatting!

class CustomerDetailsScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  void _handleMenuAction(BuildContext context, String action) async {
    // ✅ FIX 1: Add listen: false here
    final organization = Provider.of<OrganizationProvider>(
      context,
      listen: false,
    ).currentOrganization;

    final service = CustomerService();
    var orgId = organization?.id ?? '';
    if (orgId.isEmpty) return;

    if (action == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CustomerFormScreen(orgId: orgId, existingCustomer: customer),
        ),
      );
    } else if (action == 'deactivate') {
      await service.toggleCustomerStatus(orgId, customer.phone, false);

      // ✅ FIX 2: Always check if the widget is still on screen after an await
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Customer deactivated')));
      Navigator.pop(context);
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Delete Customer?'),
          content: const Text(
            'This action cannot be undone. Sales history will remain, but the profile will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await service.deleteCustomer(orgId, customer.phone);

        // ✅ FIX 2: Same context check here
        if (!context.mounted) return;

        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Customer Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) => _handleMenuAction(context, val),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit Profile'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'deactivate',
                child: ListTile(
                  leading: Icon(Icons.block),
                  title: Text('Deactivate'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Info Card
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.indigo.shade50,
                  child: Text(
                    customer.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.indigo.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      launchUrl(Uri.parse("tel:${customer.phone}")),
                  icon: const Icon(Icons.phone),
                  label: Text(customer.phone),
                ),

                // ✅ ADD THIS NEW BLOCK RIGHT HERE
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 16,
                        color: Colors.amber.shade800,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        customer.tenure,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                // ✅ END OF NEW BLOCK
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Sales', '${customer.totalSales}'),
                    _buildStatColumn('Spent', '₹${customer.totalAmountSpent}'),
                  ],
                ),
                const Divider(height: 32),
                // ✅ NEW: Dates Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDateColumn('Customer Since', customer.createdAt),
                    _buildDateColumn(
                      'Last Purchase',
                      customer.lastPurchaseDate,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Purchase History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Bottom History List (Expanded to fill remaining screen)
          Expanded(child: CustomerSalesHistory(customerPhone: customer.phone)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String val) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // ✅ NEW: Helper method to format and display dates cleanly
  Widget _buildDateColumn(String label, DateTime? date) {
    // Check for null just in case it's a manually created customer who hasn't bought anything yet
    final dateString = date != null
        ? DateFormat('dd MMM yyyy').format(date)
        : 'N/A';

    return Column(
      children: [
        Text(
          dateString,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
