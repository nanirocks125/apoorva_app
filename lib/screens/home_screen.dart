import 'package:apoorva_app/components/global_drawer.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/screens/login_screen.dart';
import 'package:apoorva_app/screens/user/users_screen.dart';
import 'package:apoorva_app/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:apoorva_app/screens/organization_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppUser loggedInUser;
  HomeScreen({super.key, required this.loggedInUser});
  final FirebaseAuth _authService = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final bool isSuperAdmin = loggedInUser.role == .superAdmin;
    final bool hasNoShops = loggedInUser.orgIds.isEmpty;

    // 1. If not an admin and no shops assigned, show the waiting room
    if (!isSuperAdmin && hasNoShops) {
      return Scaffold(
        appBar: AppBar(title: const Text('Apoorva Polaris')),
        body: _buildUnassignedView(context),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Apoorva Polaris Admin'),
          backgroundColor: const Color(0xFFFF5733),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.storefront), text: 'Organizations'),
              Tab(icon: Icon(Icons.people_alt), text: 'Global Users'),
            ],
          ),
        ),
        drawer: GlobalDrawer(
          currentUser: loggedInUser,
          onLogout: () => _handleLogout(context),
        ),
        body: TabBarView(
          children: [
            OrganizationScreen(),
            UserScreen(), // This handles the generic list of all users
          ],
        ),
      ),
    );
  }

  Widget _buildUnassignedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Visual cue (Storefront icon with a lock or clock feel)
            const Icon(
              Icons.storefront_outlined,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 32),

            // 2. Personalized Greeting
            Text(
              'Hello, ${loggedInUser.name}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 3. Clear Instruction
            const Text(
              'Your account is active, but you haven’t been assigned to a shop yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please contact your administrator to get access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF5733),
              ),
            ),
            const SizedBox(height: 48),

            // 4. Sign Out (Keep this so they can leave the app safely)
            TextButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Define the logout method INSIDE the class
  void _handleLogout(BuildContext context) async {
    // 1. Confirm with the user
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to sign out of Apoorva Polaris?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 2. Perform the sign out
      await _authService.signOut();

      // 3. Wipe the navigation stack and go to Login
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // This removes ALL previous routes
        );
      }
    }
  }
}
