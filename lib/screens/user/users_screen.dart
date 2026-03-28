import 'package:apoorva_app/enum/form_mode.dart';
import 'package:apoorva_app/screens/user/user_details_screen.dart';
import 'package:apoorva_app/screens/user/user_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/services/user_service.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF5733),
        onPressed: () => _openUserForm(context),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: userService.getAllUsersGlobal(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading users: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;

          // --- Explicit check for empty users list ---
          if (users.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.role == UserRole.admin
                        ? Colors.blue
                        : Colors.grey.shade400,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${user.email} • ${user.role.name.toUpperCase()}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openUserDetailsScreen(context, user),
                ),
              );
            },
          );
        },
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
        ),
      ),
    );
  }

  void _openUserDetailsScreen(BuildContext context, AppUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => UserDetailScreen(user: user)),
    );
  }
}
