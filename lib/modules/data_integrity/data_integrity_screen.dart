import 'package:flutter/material.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/services/customer_service.dart';
import 'package:apoorva_app/services/sale_service.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/providers/organization_provider.dart';

class DataIntegrityScreen extends StatefulWidget {
  final CustomerService? customerService; // ✅ Added for testing
  final SaleService? saleService; // ✅ Added for testing

  const DataIntegrityScreen({
    super.key,
    this.customerService,
    this.saleService,
  });

  @override
  State<DataIntegrityScreen> createState() => _DataIntegrityScreenState();
}

class _DataIntegrityScreenState extends State<DataIntegrityScreen> {
  // ✅ Initialize with injected services or defaults
  late CustomerService _customerService;
  late SaleService _saleService;

  @override
  void initState() {
    super.initState();
    // ✅ THIS IS THE CRITICAL PART
    // It assigns the mocked service if provided, otherwise the real one.
    _customerService = widget.customerService ?? CustomerService();
    _saleService = widget.saleService ?? SaleService();
  }

  @override
  Widget build(BuildContext context) {
    final orgId =
        Provider.of<OrganizationProvider>(context).currentOrganization?.id ??
        '';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Data Integrity Audit'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Missing Dates'),
              Tab(text: 'Timeline Errors'),
              Tab(text: 'Balance Mismatches'),
            ],
          ),
        ),
        body: orgId.isEmpty
            ? const Center(child: Text('No Organization Selected'))
            : StreamBuilder<List<Customer>>(
                stream: _customerService.getCustomers(orgId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final customers = snapshot.data!;

                  return TabBarView(
                    children: [
                      _buildMissingCreatedAtList(customers),
                      _buildDateLogicErrorList(customers),
                      _buildSalesMismatchAudit(orgId, customers),
                    ],
                  );
                },
              ),
      ),
    );
  }

  // 1. Issue: createdAt is null
  Widget _buildMissingCreatedAtList(List<Customer> customers) {
    final issues = customers.where((c) => c.createdAt == null).toList();
    return _buildIssueList(issues, 'Missing createdAt timestamp');
  }

  // 2. Issue: createdAt is greater than lastPurchased date
  Widget _buildDateLogicErrorList(List<Customer> customers) {
    final issues = customers.where((c) {
      if (c.createdAt == null || c.lastPurchaseDate == null) return false;
      return c.createdAt!.isAfter(c.lastPurchaseDate!);
    }).toList();
    return _buildIssueList(issues, 'Created date is after Last Purchase');
  }

  // 3. Issue: Aggregation Mismatch (Sales vs Customer Totals)
  Widget _buildSalesMismatchAudit(String orgId, List<Customer> customers) {
    return ListView.builder(
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return FutureBuilder<List<Sale>>(
          future: _saleService.getCustomerSales(orgId, customer.phone).first,
          builder: (context, saleSnapshot) {
            if (!saleSnapshot.hasData) return const SizedBox.shrink();

            final sales = saleSnapshot.data!;
            final double calculatedTotalSpent = sales.fold(
              0,
              (sum, s) => sum + s.netPayable,
            );
            final int calculatedSaleCount = sales.length;

            final bool isMismatch =
                (calculatedSaleCount != customer.totalSales) ||
                (calculatedTotalSpent != customer.totalAmountSpent);

            if (!isMismatch) return const SizedBox.shrink();

            return Card(
              color: Colors.red.shade50,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                onTap: () => _navigateToDetails(customer), // ✅ New: Navigation
                title: Text(
                  customer.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Count: DB(${customer.totalSales}) vs Actual($calculatedSaleCount)',
                    ),
                    Text(
                      'Total Spent: DB(₹${customer.totalAmountSpent}) vs Actual(₹$calculatedTotalSpent)',
                    ),
                  ],
                ),
                trailing: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIssueList(List<Customer> issues, String errorLabel) {
    if (issues.isEmpty)
      return const Center(child: Text('✅ No issues found in this category'));
    return ListView.builder(
      itemCount: issues.length,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListTile(
          onTap: () => _navigateToDetails(issues[index]), // ✅ New: Navigation
          leading: const Icon(Icons.error_outline, color: Colors.orange),
          title: Text(issues[index].name),
          subtitle: Text('$errorLabel\nPhone: ${issues[index].phone}'),
        ),
      ),
    );
  }

  void _navigateToDetails(Customer customer) {
    Navigator.pushNamed(context, '/customer-details', arguments: customer);
  }
}
