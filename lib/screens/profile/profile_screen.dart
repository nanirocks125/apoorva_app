import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:apoorva_app/enum/app_user_role.dart';

class ProfileScreen extends StatelessWidget {
  final AppUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _handleEditProfile(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildInfoSection(context),
          const SizedBox(height: 24),
          _buildOrganizationList(context),
          const SizedBox(height: 32),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  /// Profile Header with Avatar and Role Badge
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueGrey.shade100,
            child: Text(
              user.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Chip(
            label: Text(
              user.role.name.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: _getRoleColor(user.role),
          ),
        ],
      ),
    );
  }

  /// Basic Info (Email, Status, Joined Date)
  Widget _buildInfoSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text("Email"),
            subtitle: Text(user.email),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("Account Status"),
            subtitle: Text(user.status),
          ),
        ],
      ),
    );
  }

  /// The Multi-Org List (Visualizing OrganizationSnapshots)
  Widget _buildOrganizationList(BuildContext context) {
    if (user.assignedOrgs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            "Assigned Organizations",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ...user.assignedOrgs
            .map(
              (org) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      // Parsing your hex string from OrganizationSnapshot
                      color: Color(
                        int.parse(org.accentColor.replaceAll('#', '0xff')),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(org.name),
                  subtitle: Text("ID: ${org.orgId}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Action: Switch context to this organization
                  },
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _handleLogout(context),
      icon: const Icon(Icons.logout, color: Colors.red),
      label: const Text("Sign Out", style: TextStyle(color: Colors.red)),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final AuthService authService = AuthService();
    await authService.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Color _getRoleColor(AppUserRole role) {
    switch (role) {
      case AppUserRole.superAdmin:
        return Colors.deepPurple;
      case AppUserRole.support:
        return Colors.blue;
      case AppUserRole.standard:
        return Colors.grey;
    }
  }

  void _handleEditProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Edit Profile feature coming soon!")),
    );
  }
}
