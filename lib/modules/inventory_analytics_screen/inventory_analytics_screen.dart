import 'package:apoorva_app/model/category_analytics.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/services/inventory_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InventoryAnalyticsScreen extends StatefulWidget {
  const InventoryAnalyticsScreen({super.key});

  @override
  State<InventoryAnalyticsScreen> createState() =>
      _InventoryAnalyticsScreenState();
}

class _InventoryAnalyticsScreenState extends State<InventoryAnalyticsScreen> {
  final InventoryService _service = InventoryService();

  // Date range helpers
  DateTime get now => DateTime.now();
  DateTime get startOfCurrentMonth => DateTime(now.year, now.month, 1);
  DateTime get startOfLastMonth => DateTime(now.year, now.month - 1, 1);
  DateTime get endOfLastMonth => DateTime(now.year, now.month, 0, 23, 59, 59);

  @override
  Widget build(BuildContext context) {
    // CHANGE: Use context.watch or set listen to true (default)
    final organization = context
        .watch<OrganizationProvider>()
        .currentOrganization;
    final orgId = organization?.id;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Inventory Analytics"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "This Month"),
              Tab(text: "Last Month"),
            ],
          ),
        ),
        // CHANGE: Only show the lists if orgId is actually present
        body: orgId == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _AnalyticsList(
                    orgId: orgId,
                    start: startOfCurrentMonth,
                    end: DateTime.now(),
                    service: _service,
                  ),
                  _AnalyticsList(
                    orgId: orgId,
                    start: startOfLastMonth,
                    end: endOfLastMonth,
                    service: _service,
                  ),
                ],
              ),
      ),
    );
  }
}

class _AnalyticsList extends StatelessWidget {
  final String orgId;
  final DateTime start, end;
  final InventoryService service;

  const _AnalyticsList({
    required this.orgId,
    required this.start,
    required this.end,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryAnalytics>>(
      future: service.getCategoryAnalytics(orgId, start, end),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No sales data for this period."));
        }

        final data = snapshot.data!;

        // Sorting logic
        final highestByQty = List<CategoryAnalytics>.from(data)
          ..sort((a, b) => b.totalQty.compareTo(a.totalQty));

        final highestByRevenue = List<CategoryAnalytics>.from(data)
          ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection("🔥 Top Sold (Quantity)", highestByQty, isQty: true),
            const SizedBox(height: 24),
            _buildSection(
              "💰 Top Revenue (Amount)",
              highestByRevenue,
              isQty: false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection(
    String title,
    List<CategoryAnalytics> items, {
    required bool isQty,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        ...items
            .take(5)
            .map(
              (item) => ListTile(
                title: Text(item.categoryName),
                trailing: Text(
                  isQty
                      ? "${item.totalQty} items"
                      : "₹${item.totalRevenue.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
      ],
    );
  }
}
