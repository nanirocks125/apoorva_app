import 'package:apoorva_app/model/organization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../enum/account_type.dart';

class OrganizationDetailsScreen extends StatelessWidget {
  final Organization org;

  const OrganizationDetailsScreen({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(org.name),
        backgroundColor: const Color(0xFFFF5733),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () => _navigateToEdit(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section: Shop Identity ---
            _buildSectionHeader('Shop Identity'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Status',
                      org.status,
                      color: org.status == 'Active' ? Colors.green : Colors.red,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      'Created',
                      org.createdAt != null
                          ? dateFormat.format(org.createdAt!)
                          : 'N/A',
                    ),
                    const Divider(),
                    _buildDetailRow('Min Version', org.minVersion),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Section: Financial Accounts (The Array) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Financial Accounts'),
                Text(
                  'Total: ${_calculateTotalBalance()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF5733),
                  ),
                ),
              ],
            ),
            if (org.accounts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No accounts created by owner yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: org.accounts.length,
                itemBuilder: (context, index) {
                  final account = org.accounts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getAccountColor(
                          account.type,
                        ).withOpacity(0.1),
                        child: Icon(
                          _getAccountIcon(account.type),
                          color: _getAccountColor(account.type),
                        ),
                      ),
                      title: Text(
                        account.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(account.type.name.toUpperCase()),
                      trailing: Text(
                        '₹${account.currentBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets & Logic ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  String _calculateTotalBalance() {
    double total = org.accounts.fold(
      0,
      (sum, item) => sum + item.currentBalance,
    );
    return '₹${total.toStringAsFixed(2)}';
  }

  IconData _getAccountIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments_outlined;
      case AccountType.bank:
        return Icons.account_balance_outlined;
      case AccountType.upi:
        return Icons.qr_code_scanner_outlined;
    }
  }

  Color _getAccountColor(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Colors.green;
      case AccountType.bank:
        return Colors.blue;
      case AccountType.upi:
        return Colors.purple;
    }
  }

  void _navigateToEdit(BuildContext context) {
    // Logic to push to the OrganizationFormScreen in 'edit' mode
  }
}
