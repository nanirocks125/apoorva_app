import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/modules/daily-summary-report/daily_summary_report.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/services/sale_service.dart';

class SalesSummaryScreen extends StatefulWidget {
  final SaleService saleService; // Add this
  // Make it optional if you want, but default to the real one
  SalesSummaryScreen({super.key, SaleService? saleService})
    : saleService = saleService ?? SaleService();
  @override
  State<SalesSummaryScreen> createState() => SalesSummaryScreenState();
}

class SalesSummaryScreenState extends State<SalesSummaryScreen> {
  // 1. Define the Date Range State
  DateTimeRange? selectedRange;

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  // 2. Function to trigger the Modern Date Picker
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5), // Indigo matching your header
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final organization = Provider.of<OrganizationProvider>(
      context,
    ).currentOrganization;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: () => _selectDateRange(context),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      body: organization == null
          ? const Center(child: Text('No Organization available'))
          : StreamBuilder<List<DailySummary>>(
              // 3. Pass the dates to your Service (ensure your service handles these params)
              stream: widget.saleService.getDailySummaries(
                organization.id,
                startDate: selectedRange?.start,
                endDate: selectedRange?.end,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading data'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                final summaries = snapshot.data ?? [];
                final grandTotal = summaries.fold(
                  0.0,
                  (sum, item) => sum + item.totalAmount,
                );

                return CustomScrollView(
                  slivers: [
                    // --- Filter Info Chip ---
                    if (selectedRange != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildFilterBadge(),
                        ),
                      ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _buildCreativeHeader(
                          grandTotal,
                          summaries.length,
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Text(
                          "Filtered Results",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildDailyCard(summaries[index]),
                          childCount: summaries.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // A lightweight badge to show active filters
  Widget _buildFilterBadge() {
    final df = DateFormat('MMM d');
    return Row(
      children: [
        Chip(
          backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
          side: BorderSide.none,
          label: Text(
            "${df.format(selectedRange!.start)} - ${df.format(selectedRange!.end)}",
            style: const TextStyle(
              color: Color(0xFF4F46E5),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          deleteIcon: const Icon(
            Icons.close,
            size: 14,
            color: Color(0xFF4F46E5),
          ),
          onDeleted: () => setState(() => selectedRange = null),
        ),
      ],
    );
  }

  Widget _buildCreativeHeader(double total, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)], // Indigo Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "TOTAL REVENUE",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              formatCurrency(total),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Reporting over $count Days",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCard(DailySummary day) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/sales-history', arguments: day.date);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.03)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Date Icon/Badge
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('dd').format(day.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    Text(
                      DateFormat('MMM').format(day.date).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Middle Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(day.date),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "${day.saleCount} transactions",
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                formatCurrency(day.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
