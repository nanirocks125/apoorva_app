import 'package:apoorva_app/components/global_drawer.dart';
import 'package:apoorva_app/enum/form_mode.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/screens/organization/organization_details_screen.dart';
import 'package:apoorva_app/screens/organization/organization_form_screen.dart';
import 'package:apoorva_app/services/auth_service.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:apoorva_app/services/platform_stats_service.dart';
import 'package:flutter/material.dart';

class SuperAdminDashboard extends StatelessWidget {
  final AppUser user;
  final PlatformStatsService _statsService;

  SuperAdminDashboard({
    super.key,
    required this.user,
    PlatformStatsService? statsService, // Add this
  }) : _statsService = statsService ?? PlatformStatsService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polaris Central Control'),
        actions: [
          IconButton(icon: const Icon(Icons.hub_outlined), onPressed: () {}),
        ],
      ),
      drawer: GlobalDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlatformOverview(),
            const SizedBox(height: 24),

            // --- PLATFORM KPI GRID ---
            FutureBuilder<PlatformStats>(
              future: _statsService.getLivePlatformStats(),
              builder: (context, snapshot) {
                final bool isLoading =
                    snapshot.connectionState == ConnectionState.waiting;
                final stats = snapshot.data;

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
                    _buildStatCard(
                      'Active Organizations',
                      isLoading ? '...' : '${stats?.activeOrgs ?? 0}',
                      Icons.business_center,
                      Colors.indigo,
                    ),
                    _buildStatCard(
                      'Global Users',
                      isLoading ? '...' : '${stats?.globalUsers ?? 0}',
                      Icons.groups_3,
                      Colors.teal,
                    ),
                    _buildStatCard(
                      'New Requests',
                      isLoading
                          ? '...'
                          : stats?.newRequests.toString().padLeft(2, '0') ??
                                '00',
                      Icons.pending_actions,
                      Colors.amber,
                    ),
                    _buildStatCard(
                      'System Health',
                      'Optimal', // You can later make this dynamic based on latency
                      Icons.dns_outlined,
                      Colors.green,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Organization Management'),
            const SizedBox(height: 12),

            // --- CORE ACTIONS ---
            Row(
              children: [
                Expanded(
                  child: _buildActionTile(
                    context,
                    'Register Org',
                    Icons.add_chart,
                    Colors.orange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrganizationFormScreen(
                            mode: FormMode
                                .create, // This tells the form to show 'New Shop' UI
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionTile(
                    context,
                    'System Logs',
                    Icons.terminal,
                    Colors.blueGrey,
                    () => _navTo(context, '/logs'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('Recently Registered Organizations'),
            const SizedBox(height: 12),
            _buildOrganizationList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformOverview() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Overview',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'Manage isolated organizations and global system access.',
          style: TextStyle(color: Colors.grey),
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
            Icon(icon, color: color, size: 24),
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

  Widget _buildActionTile(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Section Titles
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  // Navigation Helper
  void _navTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  // The Organization List Widget
  Widget _buildOrganizationList() {
    final OrganizationService orgService = OrganizationService();

    return StreamBuilder<List<Organization>>(
      stream: orgService.getOrganizations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orgs = snapshot.data ?? [];

        if (orgs.isEmpty) {
          return const Card(
            child: ListTile(
              title: Text('No organizations registered yet'),
              subtitle: Text('Tap "Register Org" to get started'),
            ),
          );
        }

        // Showing only the last 3-5 for the dashboard view
        final recentOrgs = orgs.take(5).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentOrgs.length,
          itemBuilder: (context, index) {
            final org = recentOrgs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFF5733),
                  child: Icon(Icons.business, color: Colors.white, size: 20),
                ),
                title: Text(
                  org.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('ID: ${org.id}'),
                trailing: const Icon(Icons.chevron_right),
                // Inside SuperAdminDashboard's _buildTenantList itemBuilder
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrganizationDetailsScreen(org: org),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
