import 'package:apoorva_app/components/global_drawer.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class OrganizationDashboard extends StatelessWidget {
  final Organization organization;
  final AppUser currentUser;

  const OrganizationDashboard({
    super.key,
    required this.organization,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(organization.name),
        actions: [
          // Quick toggle for managers who handle multiple locations
          if (currentUser.assignedOrgs.length > 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/org-selector'),
              tooltip: 'Switch Shop',
            ),
        ],
      ),
      drawer: GlobalDrawer(
        currentUser: currentUser,
        onLogout: () => _handleLogout(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShopHeader(),
            const SizedBox(height: 24),

            // --- REAL-TIME REVENUE & ALERTS ---
            _buildLiveStatusGrid(),

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
                  'Point of Sale',
                  Icons.point_of_sale,
                  Colors.green,
                  '/pos',
                ),
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
        onPressed: () =>
            Navigator.pushNamed(context, '/pos', arguments: organization.id),
        label: const Text('New Sale'),
        icon: const Icon(Icons.add_shopping_cart),
        backgroundColor: const Color(0xFFFF5733),
      ),
    );
  }

  Widget _buildShopHeader() {
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

  Widget _buildLiveStatusGrid() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent:
            250, // కార్డ్ గరిష్ట వెడల్పును 250 కి పరిమితం చేస్తుంది
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3, // కార్డ్ పొడవు, వెడల్పు నిష్పత్తి
      ),
      children: [
        _buildStatCard(
          'Sales Today',
          '₹12,450',
          Icons.trending_up,
          Colors.green,
        ),
        _buildStatCard(
          'Low Stock',
          '05 Items',
          Icons.warning_amber_rounded,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with soft background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatusCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
