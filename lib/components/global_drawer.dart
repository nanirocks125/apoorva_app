import 'package:flutter/material.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/enum/app_user_role.dart';

class GlobalDrawer extends StatelessWidget {
  final AppUser currentUser;
  final VoidCallback onLogout;

  const GlobalDrawer({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the user is a Super Admin
    final bool isSuperAdmin = currentUser.role == AppUserRole.superAdmin;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Home Dashboard',
                  onTap: () => Navigator.pop(context),
                ),

                // --- ADMIN ONLY SECTION ---
                if (isSuperAdmin) ...[
                  const Divider(),
                  _buildSectionHeader('Management'),
                  _buildDrawerItem(
                    icon: Icons.people_alt_outlined,
                    title: 'Global Users',
                    onTap: () => _navigateTo(context, '/users'),
                  ),
                  _buildDrawerItem(
                    icon: Icons.storefront_outlined,
                    title: 'Organizations',
                    onTap: () => _navigateTo(context, '/organizations'),
                  ),
                ],

                const Divider(),
                _buildSectionHeader('Account'),
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  onTap: () => _navigateTo(context, '/profile'),
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'App Settings',
                  onTap: () => _navigateTo(context, '/settings'),
                ),
              ],
            ),
          ),

          // --- LOGOUT AT THE BOTTOM ---
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Sign Out',
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: onLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: Color(0xFFFF5733)),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          currentUser.name[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF5733),
          ),
        ),
      ),
      accountName: Text(
        currentUser.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      accountEmail: Text(currentUser.email),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pop(context); // Close drawer first
    Navigator.pushNamed(context, routeName);
  }
}
