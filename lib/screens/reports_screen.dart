import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatelessWidget {
  final String orgId;

  const ReportsScreen({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Insights')),
      body: StreamBuilder<QuerySnapshot>(
        // Fetching all sales for the current month for a complete view
        stream: FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('sales')
            .where('timestamp', isGreaterThanOrEqualTo: _startOfMonth())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final sales = snapshot.data!.docs;
          final metrics = _calculateMetrics(sales);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Key Performance Indicators'),
                _buildKpiGrid(metrics),

                const SizedBox(height: 32),
                _buildSectionHeader('Payment Reconciliation (Cash Integrity)'),
                _buildPaymentPieChart(metrics),

                const SizedBox(height: 32),
                _buildSectionHeader('Top Moving Designs'),
                _buildTopItemsTable(sales),

                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          );
        },
      ),
    );
  }

  // Logic to calculate monthly totals, payment splits, and sharing rates
  Map<String, dynamic> _calculateMetrics(List<QueryDocumentSnapshot> docs) {
    double totalRevenue = 0;
    double upiTotal = 0;
    double cashTotal = 0;
    int sharedCount = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['netPayable'] ?? 0).toDouble();
      totalRevenue += amount;

      if (data['paymentMode'] == 'UPI') upiTotal += amount;
      if (data['paymentMode'] == 'Cash') cashTotal += amount;
      if (data['whatsapp_status'] == 'sent') sharedCount++;
    }

    return {
      'revenue': totalRevenue,
      'upi': upiTotal,
      'cash': cashTotal,
      'shareRate': docs.isEmpty ? 0 : (sharedCount / docs.length) * 100,
    };
  }

  // --- UI COMPONENTS ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> m) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatTile(
          'Monthly Rev',
          '₹${m['revenue'].toStringAsFixed(0)}',
          Colors.blue,
        ),
        _buildStatTile(
          'Share Rate',
          '${m['shareRate'].toStringAsFixed(1)}%',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPieChart(Map<String, dynamic> m) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: m['upi'],
              color: Colors.purple,
              title: 'UPI',
              radius: 50,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            PieChartSectionData(
              value: m['cash'],
              color: Colors.orange,
              title: 'Cash',
              radius: 50,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopItemsTable(List<QueryDocumentSnapshot> docs) {
    // Basic aggregation for best sellers could be implemented here
    return const Card(
      child: ListTile(
        leading: Icon(Icons.star, color: Colors.amber),
        title: Text('Stone Haram - V1'),
        subtitle: Text('Sold 12 times this month'),
        trailing: Text(
          '₹45,000',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  DateTime _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }
}
