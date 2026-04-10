import 'package:apoorva_app/services/customer_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/model/customer/customer.dart';

class CustomerAnalyticsScreen extends StatefulWidget {
  const CustomerAnalyticsScreen({super.key});

  @override
  State<CustomerAnalyticsScreen> createState() =>
      _CustomerAnalyticsScreenState();
}

class _CustomerAnalyticsScreenState extends State<CustomerAnalyticsScreen> {
  final CustomerService _service = CustomerService();

  bool _isLoading = true;
  List<Customer> _vipCustomers = [];
  List<Customer> _lapsedCustomers = [];
  Map<String, List<Customer>> _upcomingEvents = {};

  @override
  void initState() {
    super.initState();
    _loadAllAnalytics();
  }

  Future<void> _loadAllAnalytics() async {
    final orgId = Provider.of<OrganizationProvider>(
      context,
      listen: false,
    ).currentOrganization?.id;
    if (orgId == null) return;

    try {
      // Run queries concurrently for faster loading
      final results = await Future.wait([
        _service.getTopVIPCustomers(orgId),
        _service.getLapsedCustomers(orgId),
        _service.getThisMonthsEvents(orgId),
      ]);

      setState(() {
        _vipCustomers = results[0] as List<Customer>;
        _lapsedCustomers = results[1] as List<Customer>;
        _upcomingEvents = results[2] as Map<String, List<Customer>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading customer analytics: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Customer Insights',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader("🎁 Action Needed: This Month's Events"),
                  _buildEventsCards(),

                  const SizedBox(height: 24),
                  _buildSectionHeader("👑 Top VIP Customers (Reward Them)"),
                  _buildCustomerList(_vipCustomers, isVip: true),

                  const SizedBox(height: 24),
                  _buildSectionHeader("⚠️ At Risk (No visits in 6 months)"),
                  _buildCustomerList(_lapsedCustomers, isVip: false),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildEventsCards() {
    final bdays = _upcomingEvents['birthdays'] ?? [];
    final annivs = _upcomingEvents['anniversaries'] ?? [];

    if (bdays.isEmpty && annivs.isEmpty) {
      return const Text(
        "No events this month.",
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: [
        if (bdays.isNotEmpty)
          _buildEventSummaryCard("Birthdays", bdays.length, Colors.purple),
        if (annivs.isNotEmpty)
          _buildEventSummaryCard("Anniversaries", annivs.length, Colors.pink),
      ],
    );
  }

  Widget _buildEventSummaryCard(String eventType, int count, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(Icons.cake, color: color),
        title: Text(
          "$count Upcoming $eventType",
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: const Text("Tap to view and send offers"),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
        onTap: () {
          // TODO: Navigate to a detailed list of these specific customers
        },
      ),
    );
  }

  Widget _buildCustomerList(List<Customer> customers, {required bool isVip}) {
    if (customers.isEmpty) {
      return const Text(
        "No data available yet.",
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: customers.map((c) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isVip
                  ? Colors.amber.shade100
                  : Colors.red.shade50,
              child: Icon(
                isVip ? Icons.star : Icons.history,
                color: isVip ? Colors.amber.shade800 : Colors.red.shade400,
              ),
            ),
            title: Text(
              c.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(c.phone),
            trailing: isVip
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${c.totalSales} sales",
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.message, color: Colors.green),
                    onPressed: () {
                      // TODO: Launch WhatsApp URL with a "We miss you" template
                    },
                  ),
          ),
        );
      }).toList(),
    );
  }
}
