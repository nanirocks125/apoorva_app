import 'package:apoorva_app/enum/form_mode.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/user/app_user_snapshot.dart';
import 'package:apoorva_app/screens/home/user/user_details_screen.dart';
import 'package:apoorva_app/screens/home/user/user_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/services/user_service.dart';

class UserScreen extends StatelessWidget {
  final UserService _userService; // Add this
  UserScreen({
    super.key,
    this.org,
    UserService? userService, // Optional injection
  }) : _userService = userService ?? UserService();
  final Organization? org; // Optional: Provide for branch staff list

  // Helper to handle role-based colors for the UI
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return const Color(0xFFFF5733);
      case 'manager':
        return Colors.blue.shade600;
      case 'admin':
        return Colors.blue.shade800;
      case 'staff':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the authoritative stream based on context
    return Scaffold(
      appBar: AppBar(
        title: Text(org != null ? '${org!.name} Staff' : 'Global Users'),
        backgroundColor: const Color(0xFFFF5733),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openUserForm(context),
        backgroundColor: const Color(0xFFFF5733),
        tooltip: 'Add User',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder(
        // Use Snapshot stream for Org, Global stream for Platform Admin
        stream: org != null
            ? _userService.getOrganizationUsers(org!.id)
            : _userService.getAllUsersGlobal(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          if (data.isEmpty) return _buildEmptyState(context);

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];

              // --- DYNAMIC DATA EXTRACTION ---
              String name, email, displayRole, userId;

              if (item is AppUserSnapshot) {
                // AUTHORITATIVE: Pulled from organizations/{id}/users/{uid}
                name = item.name;
                email = item.email;
                displayRole =
                    item.orgRole; // This is the exact role for this shop
                userId = item.uid;
              } else {
                // PLATFORM: Pulled from /users/{uid}
                final user = item as AppUser;
                name = user.name;
                email = user.email;
                displayRole = user.role.name;
                userId = user.id;
              }

              return _buildUserCard(context, name, email, displayRole, userId);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    String name,
    String email,
    String role,
    String userId,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role).withOpacity(0.1),
          child: Text(
            name[0].toUpperCase(),
            style: TextStyle(color: _getRoleColor(role)),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(email),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getRoleColor(role).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getRoleColor(role).withOpacity(0.3)),
          ),
          child: Text(
            role.toUpperCase(),
            style: TextStyle(
              color: _getRoleColor(role),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _openUserDetailsScreen(context, userId),
      ),
    );
  }

  // Helper widget for a clean empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the orange + button to invite\nyour first staff member or manager.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _openUserForm(BuildContext context, {AppUser? user}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserFormScreen(
          user: user,
          mode: user == null ? FormMode.create : FormMode.edit,
          org: org, // Pass the organization context if available
          userService: _userService,
        ),
      ),
    );
  }

  Future<void> _openUserDetailsScreen(
    BuildContext context,
    String userId,
  ) async {
    // 1. Show a non-cancelable loading dialog to provide immediate feedback
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF5733)),
      ),
    );

    try {
      // 2. Fetch the authoritative root profile from /users/{userId}
      final AppUser? fullUser = await _userService.getUserById(userId);

      // 3. Pop the loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (fullUser != null) {
        // 4. Navigate only if we have the data
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UserDetailScreen(user: fullUser),
            ),
          );
        }
      } else {
        throw Exception("User profile not found.");
      }
    } catch (e) {
      // 5. Cleanup: Pop dialog and show error if the fetch fails
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching details: $e')));
      }
    }
  }
}
