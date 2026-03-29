import 'package:apoorva_app/enum/app_user_role.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/organization/organization_snapshot.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:apoorva_app/services/user_service.dart';
import 'package:flutter/material.dart';

class ShopAssignmentPicker extends StatefulWidget {
  final AppUser user;
  const ShopAssignmentPicker({super.key, required this.user});

  @override
  State<ShopAssignmentPicker> createState() => _ShopAssignmentPickerState();
}

class _ShopAssignmentPickerState extends State<ShopAssignmentPicker> {
  final OrganizationService _orgService = OrganizationService();
  final UserService _userService = UserService();

  String? _selectedOrgId;
  AppUserRole _selectedRole = AppUserRole.staff;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.85,
      // 1. Listen to the user's LIVE mappings
      child: StreamBuilder<List<OrganizationSnapshot>>(
        stream: _userService.getUserShops(widget.user.id),
        builder: (context, mappingSnapshot) {
          // 2. Listen to the GLOBAL organizations
          return StreamBuilder<List<Organization>>(
            stream: _orgService.getOrganizations(),
            builder: (context, orgSnapshot) {
              if (!orgSnapshot.hasData || !mappingSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allOrgs = orgSnapshot.data!;
              // 3. Extract the IDs from the LIVE mappings stream
              final assignedIds = mappingSnapshot.data!
                  .map((m) => m.orgId)
                  .toList();

              final assignedOrgs = allOrgs
                  .where((o) => assignedIds.contains(o.id))
                  .toList();
              final availableOrgs = allOrgs
                  .where((o) => !assignedIds.contains(o.id))
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Shop Access',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),
                  Expanded(
                    child: ListView(
                      children: [
                        if (assignedOrgs.isNotEmpty) ...[
                          _buildHeader('ACTIVE ASSIGNMENTS'),
                          ...assignedOrgs.map((org) => _buildAssignedTile(org)),
                          const SizedBox(height: 24),
                        ],
                        if (availableOrgs.isNotEmpty) ...[
                          _buildHeader('AVAILABLE SHOPS'),
                          ...availableOrgs.map(
                            (org) => _buildAvailableTile(org),
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

  Widget _buildAvailableTile(Organization org) {
    bool isConfiguring = _selectedOrgId == org.id;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.store_outlined),
            title: Text(org.name),
            trailing: isConfiguring
                ? null
                : ElevatedButton(
                    onPressed: () => setState(() => _selectedOrgId = org.id),
                    child: const Text('Assign'),
                  ),
          ),
          if (isConfiguring)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<AppUserRole>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role in Shop',
                        border: OutlineInputBorder(),
                      ),
                      items: AppUserRole.values
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
                    icon: const Icon(
                      Icons.check_circle,
                      color: Color(0xFFFF5733),
                      size: 40,
                    ),
                    onPressed: _isSaving ? null : () => _handleMap(org),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: () => setState(() => _selectedOrgId = null),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleMap(Organization org) async {
    setState(() => _isSaving = true);
    try {
      await _userService.mapUserToOrganization(
        fullUser: widget.user,
        fullOrg: org,
        orgRole: _selectedRole.name, // Pass the specific role!
      );
      setState(() {
        _selectedOrgId = null;
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
      // Show error...
    }
  }

  void _handleUnmap(String orgId) async {
    await _userService.unmapUserFromOrganization(
      userId: widget.user.id,
      orgId: orgId,
    );
  }
}
