import 'package:apoorva_app/enum/app_user_role.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/organization/organization_snapshot.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/model/user/app_user_snapshot.dart';
import 'package:apoorva_app/services/user_service.dart';
import 'package:flutter/material.dart';

class UserAssignmentPicker extends StatefulWidget {
  final Organization organization;
  const UserAssignmentPicker({super.key, required this.organization});

  @override
  State<UserAssignmentPicker> createState() => _UserAssignmentPickerState();
}

class _UserAssignmentPickerState extends State<UserAssignmentPicker> {
  final UserService _userService = UserService();
  String? _configuringUserId;
  UserRole _selectedRole = UserRole.staff;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.85,
      child: StreamBuilder<List<AppUserSnapshot>>(
        stream: _userService.getOrganizationUsers(widget.organization.id),
        builder: (context, staffSnapshot) {
          return StreamBuilder<List<AppUser>>(
            stream: _userService.getAllUsersGlobal(),
            builder: (context, globalSnapshot) {
              if (!staffSnapshot.hasData || !globalSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allUsers = globalSnapshot.data!;
              final assignedUids = staffSnapshot.data!
                  .map((s) => s.uid)
                  .toSet();

              // Split into two groups
              final activeStaff = allUsers
                  .where((u) => assignedUids.contains(u.id))
                  .toList();
              final availableUsers = allUsers
                  .where((u) => !assignedUids.contains(u.id))
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Shop Staff',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),

                  Expanded(
                    child: ListView(
                      children: [
                        // --- ACTIVE STAFF SECTION ---
                        if (activeStaff.isNotEmpty) ...[
                          _buildHeader('ACTIVE STAFF'),
                          ...activeStaff.map(
                            (user) => _buildActiveUserTile(user),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // --- AVAILABLE USERS SECTION ---
                        if (availableUsers.isNotEmpty) ...[
                          _buildHeader('AVAILABLE TO ADD'),
                          ...availableUsers.map(
                            (user) => _buildAvailableUserTile(user),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_isSaving) const LinearProgressIndicator(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActiveUserTile(AppUser user) {
    return Card(
      color: Colors.green.shade50, // Matches your screenshot's style
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(user.email),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => _handleUnmap(user.id),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAssignedTile(Organization org) {
    return Card(
      color: Colors.green.shade50,
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text(
          org.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Authorized Access'),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () => _handleUnmap(org.id),
        ),
      ),
    );
  }

  Widget _buildAvailableUserTile(AppUser user) {
    bool isConfiguring = _configuringUserId == user.id;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(child: Text(user.name[0])),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: isConfiguring
                ? null
                : ElevatedButton(
                    onPressed: () =>
                        setState(() => _configuringUserId = user.id),
                    child: const Text('Add'),
                  ),
          ),
          if (isConfiguring)
            _buildRoleConfig(user), // The dropdown + confirm checkmark
        ],
      ),
    );
  }

  Widget _buildRoleConfig(AppUser user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<UserRole>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Assigned Role',
                border: OutlineInputBorder(),
              ),
              items: UserRole.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 42),
            onPressed: _isSaving ? null : () => _confirmAssignment(user),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            onPressed: () => setState(() => _configuringUserId = null),
          ),
        ],
      ),
    );
  }

  void _confirmAssignment(AppUser user) async {
    setState(() => _isSaving = true);
    try {
      await _userService.mapUserToOrganization(
        fullUser: user,
        fullOrg: widget.organization,
        orgRole: _selectedRole.name,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      // Handle permission/network errors here
    }
  }

  void _handleUnmap(String userId) async {
    // 1. Prevent double-taps
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // 2. Call the service to perform the bidirectional delete
      await _userService.unmapUserFromOrganization(
        userId: userId,
        orgId: widget.organization.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff member removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 3. Reset loading state if we are still on this screen
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
