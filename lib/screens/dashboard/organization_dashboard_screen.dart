import 'package:apoorva_app/components/global_drawer.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/providers/auth_provider.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OrganizationDashboard extends StatelessWidget {
  const OrganizationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    final organization = Provider.of<OrganizationProvider>(
      context,
    ).currentOrganization;

    return Scaffold(
      appBar: AppBar(
        title: Text(organization?.name ?? 'NA'),
        actions: [
          // Quick toggle for managers who handle multiple locations
          if (currentUser != null)
            if (currentUser.assignedOrgs.length > 1)
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/org-selector'),
                tooltip: 'Switch Shop',
              ),
        ],
      ),
      drawer: GlobalDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (organization != null) _buildShopHeader(organization),
            const SizedBox(height: 24),

            // --- REAL-TIME REVENUE & ALERTS ---
            if (organization != null) _buildLiveStatusGrid(organization),

            const SizedBox(height: 32),
            const Text(
              'Operations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // --- OPERATIONS GRID (POS, Inventory, etc.) ---
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio:
                    1.1, // Operations కార్డ్స్ కొంచెం పొడవుగా ఉండటానికి
              ),
              children: [
                _buildActionCard(
                  context,
                  'Customers',
                  Icons.people_outline,
                  Colors.orange,
                  '/customers',
                ), // NEW
                _buildActionCard(
                  context,
                  'Inventory',
                  Icons.inventory_2_outlined,
                  Colors.blue,
                  '/inventory',
                ),
                _buildActionCard(
                  context,
                  'Staff List',
                  Icons.badge_outlined,
                  Colors.orange,
                  '/staff',
                ),
                _buildActionCard(
                  context,
                  'Sales History',
                  Icons.history_outlined,
                  Colors.teal,
                  '/sales-history',
                ), // NEW
                _buildActionCard(
                  context,
                  'Reports',
                  Icons.analytics_outlined,
                  Colors.purple,
                  '/reports',
                ),
              ],
            ),
          ],
        ),
      ),
      // Floating Action Button for the most common task: A New Sale
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          print('triggering crash');
          // FirebaseCrashlytics.instance.crash();
          Navigator.pushNamed(context, '/pos', arguments: organization);
        },
        label: const Text('New Sale', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        backgroundColor: const Color(0xFFFF5733),
      ),
    );
  }

  Widget _buildShopHeader(Organization organization) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xFFFF5733),
          child: Icon(Icons.storefront, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Branch: ${organization.name}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Active Session: Open',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveStatusGrid(Organization organization) {
    // 1. Calculate the start of the current day (00:00:00)
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      children: [
        // --- LIVE SALES TODAY STREAM ---
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('organizations')
              .doc(organization.id)
              .collection('sales')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .snapshots(),
          builder: (context, snapshot) {
            double totalRevenue = 0;
            int totalSalesCount = 0;

            if (snapshot.hasData) {
              // Aggregate netPayable from all sales today
              final docs = snapshot.data!.docs;
              totalSalesCount = docs.length;
              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalRevenue += (data['netPayable'] ?? 0).toDouble();
              }
            }

            return _buildStatCard(
              'Sales Today',
              '₹${totalRevenue.toStringAsFixed(0)}', // Live aggregated value
              Icons.trending_up,
              snapshot.hasError ? Colors.grey : Colors.teal,
              trailingText: '$totalSalesCount Sales',
            );
          },
        ),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('organizations')
              .doc(organization.id)
              .collection('sales')
              .snapshots(),
          builder: (context, snapshot) {
            double totalLifetimeAmount = 0;
            int totalSalesCount = 0;

            if (snapshot.hasData) {
              final docs = snapshot.data!.docs;
              totalSalesCount = docs.length;

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalLifetimeAmount += (data['netPayable'] ?? 0).toDouble();
              }
            }

            // Pass both values to the stat card
            return _buildStatCard(
              'Total Revenue',
              '₹${totalLifetimeAmount.toStringAsFixed(0)}',
              Icons.payments_outlined,
              Colors.teal,
              trailingText: '$totalSalesCount Sales', // New parameter
            );
          },
        ),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('organizations')
              .doc(organization.id)
              .collection('customers') // Path to your customers sub-collection
              .snapshots(),
          builder: (context, snapshot) {
            int totalCustomers = 0;

            if (snapshot.hasData) {
              // Total count of documents in the customers collection
              totalCustomers = snapshot.data!.docs.length;
            }

            return _buildStatCard(
              'Total Customers',
              totalCustomers.toString().padLeft(
                2,
                '0',
              ), // Neat padding for single digits
              Icons.groups_outlined,
              Colors.orange,
              trailingText: 'Till Date',
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? trailingText, // Added optional trailing text
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          12.0,
        ), // Padding slightly reduced to avoid overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    final organization = Provider.of<OrganizationProvider>(
      context,
    ).currentOrganization;
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route, arguments: organization),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final AuthService authService = AuthService();
    await authService.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
