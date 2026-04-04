import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/services/user_service.dart';
import 'package:flutter/material.dart';

class UserManagementScreen extends StatelessWidget {
  final String orgId;
  final String orgName;
  final UserService _userService = UserService();

  UserManagementScreen({super.key, required this.orgId, required this.orgName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$orgName Staff')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openUserForm(context),
        child: const Icon(Icons.person_add),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: _userService.getStaffForOrg(orgId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user.name[0])),
                title: Text(user.name),
                subtitle: Text('${user.email} • ${user.role.name}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _openUserForm(context, user: user),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openUserForm(BuildContext context, {AppUser? user}) {
    // Navigate to UserFormScreen (implementation below)
  }
}
