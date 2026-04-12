import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/screens/auth/login_screen.dart';
import 'package:apoorva_app/screens/home/version_block_screen.dart';
import 'package:apoorva_app/screens/organization/organization_selection_screen.dart';
import 'package:apoorva_app/screens/dashboard/super_admin_dashboard.dart';
import 'package:apoorva_app/screens/pos_screen.dart';
import 'package:apoorva_app/services/auth_service.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:apoorva_app/services/platform_stats_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomeScreen extends StatelessWidget {
  final AppUser loggedInUser;
  final OrganizationService _orgService; // Changed from final initialization
  final AuthService _authService;
  final PlatformStatsService? _statsService;
  HomeScreen({
    super.key,
    required this.loggedInUser,
    OrganizationService? orgService, // Optional injection
    AuthService? authService,
    PlatformStatsService? statsService, // 2. Add to constructor
  }) : _orgService = orgService ?? OrganizationService(),
       _authService = authService ?? AuthService(),
       _statsService = statsService; // 3. Store it

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, packageSnapshot) {
        if (packageSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final String currentAppVersion =
            packageSnapshot.data?.version ?? "0.0.0";
        final bool isSuperAdmin = loggedInUser.role == .superAdmin;
        final int shopCount = loggedInUser.assignedOrgs.length;
        if (isSuperAdmin) {
          return SuperAdminDashboard(
            user: loggedInUser,
            statsService: _statsService,
          );
        }

        // 1. If not an admin and no shops assigned, show the waiting room
        if (shopCount == 0) {
          return Scaffold(
            appBar: AppBar(title: const Text('Apoorva Polaris')),
            body: _buildUnassignedView(context),
          );
        }

        // 3. Shop Selector (If they manage multiple branches)
        if (shopCount > 1) {
          return OrganizationSelectionScreen(user: loggedInUser);
        }

        return _buildOrganizationDashboardView(
          context,
          loggedInUser,
          currentAppVersion,
        );
      },
    );
  }

  Widget _buildOrganizationDashboardView(
    BuildContext context,
    AppUser user,
    String currentAppVersion,
  ) {
    final String orgId = loggedInUser.assignedOrgs.first.orgId;

    return FutureBuilder<Organization?>(
      future: _orgService.getOrganizationById(
        orgId,
      ), // You'll need this helper in OrgService
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final Organization org = snapshot.data!;

          // 2. Version Check Logic
          // Blocking if app version is lower than minVersion
          if (_isUpdateRequired(currentAppVersion, org.minVersion) &&
              (!kIsWeb)) {
            return VersionBlockScreen(
              minVersion: org.minVersion,
              currentAppVersion: currentAppVersion,
              onLogout: () => _handleLogout,
            );
          }

          return PosScreen();
        }

        // Fallback if the shop was deleted but the user still has the ID
        return _buildUnassignedView(context);
      },
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
      try {
        await _authService.signOut();

        // 3. Wipe the navigation stack and go to Login
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false, // This removes ALL previous routes
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign out failed. Please try again.')),
          );
        }
      }
      // 2. Perform the sign out
    }
  }

  bool _isUpdateRequired(String current, String? minRequired) {
    if (minRequired == null || minRequired.isEmpty) return false;

    // Simple equality check as per your requirement:
    // return current == minRequired;

    // Recommendation: Real version comparison logic
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> minParts = minRequired.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        int c = i < currentParts.length ? currentParts[i] : 0;
        int m = i < minParts.length ? minParts[i] : 0;
        if (c < m) return true; // Current is older than min
        if (c > m) return false; // Current is newer
      }
    } catch (e) {
      return current == minRequired; // Fallback to exact match
    }
    return false;
  }
}
