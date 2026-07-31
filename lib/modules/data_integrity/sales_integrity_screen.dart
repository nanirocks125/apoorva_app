import 'package:flutter/material.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/services/sale_service.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:intl/intl.dart';

class SalesIntegrityScreen extends StatefulWidget {
  final SaleService? saleService;

  const SalesIntegrityScreen({super.key, this.saleService});

  @override
  State<SalesIntegrityScreen> createState() => _SalesIntegrityScreenState();
}

class _SalesIntegrityScreenState extends State<SalesIntegrityScreen> {
  late SaleService _saleService;

  @override
  void initState() {
    super.initState();
    _saleService = widget.saleService ?? SaleService();
  }

  @override
  Widget build(BuildContext context) {
    final orgId =
        Provider.of<OrganizationProvider>(context).currentOrganization?.id ??
        '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sales Integrity Audit'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pricing Errors (MRP < Final)'),
              Tab(text: 'Suspicious Discounts'),
            ],
          ),
        ),
        body: orgId.isEmpty
            ? const Center(child: Text('No Organization Selected'))
            : StreamBuilder<List<Sale>>(
                // Fetching last 30 days or all sales for audit
                stream: _saleService.getTotalSales(orgId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sales = snapshot.data!;
                  return TabBarView(
                    children: [
                      _buildPricingErrorList(sales),
                      _buildExtremeDiscountList(sales),
                    ],
                  );
                },
              ),
      ),
    );
  }

  /// 1. Main Audit: Sticker Price < Final Price
  Widget _buildPricingErrorList(List<Sale> sales) {
    final issues = sales.where((sale) {
      // Logic: Check if total net payable exceeds the total MRP
      // Or check individual items if your Sale model supports it
      return sale.netPayable > sale.totalMRP;
    }).toList();

    if (issues.isEmpty) {
      return _buildEmptyState('No pricing integrity issues found.');
    }

    return ListView.builder(
      itemCount: issues.length,
      itemBuilder: (context, index) {
        final sale = issues[index];
        final overcharge = sale.netPayable - sale.totalMRP;

        return Card(
          color: Colors.red.shade50,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.trending_up, color: Colors.white),
            ),
            title: Text('Sale #${sale.id}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${sale.customerName}'),
                Text(
                  'MRP: ₹${sale.totalMRP} vs Final: ₹${sale.netPayable}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Excess Amount: ₹${overcharge.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.pushNamed(context, '/sale-details', arguments: sale),
          ),
        );
      },
    );
  }

  /// 2. Bonus Audit: High Discounts (e.g., > 50%)
  Widget _buildExtremeDiscountList(List<Sale> sales) {
    final issues = sales.where((sale) {
      if (sale.totalMRP == 0) return false;
      final discountPct =
          ((sale.totalMRP - sale.netPayable) / sale.totalMRP) * 100;
      return discountPct > 50; // Flagging anything over 50% discount
    }).toList();

    return _buildGenericSaleList(issues, 'High Discount (>50%)');
  }

  Widget _buildGenericSaleList(List<Sale> issues, String label) {
    if (issues.isEmpty) return _buildEmptyState('No issues found.');
    return ListView.builder(
      itemCount: issues.length,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          title: Text('Sale #${issues[index].id}'),
          subtitle: Text('$label\nAmount: ₹${issues[index].netPayable}'),
          onTap: () => Navigator.pushNamed(
            context,
            '/sale-details',
            arguments: issues[index],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}
