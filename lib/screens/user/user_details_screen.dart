import 'package:apoorva_app/components/shop_assignment_picker.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/organization/organization_snapshot.dart';
import 'package:apoorva_app/screens/organization/organization_details_screen.dart';
import 'package:apoorva_app/screens/user/user_form_screen.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:apoorva_app/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/enum/form_mode.dart';

class UserDetailScreen extends StatelessWidget {
  final AppUser user;

  const UserDetailScreen({super.key, required this.user});

  UserService get _userService => UserService();
  OrganizationService get _organizationService => OrganizationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildInfoSection(context),
            _buildOrganizationSection(context),
            const SizedBox(height: 20),
            _buildDeleteButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFF5733),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              user.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 40,
                color: Color(0xFFFF5733),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(user.email, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.security, color: Color(0xFFFF5733)),
              title: const Text('System Role'),
              trailing: Chip(label: Text(user.role.name.toUpperCase())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.calendar_today,
                color: Color(0xFFFF5733),
              ),
              title: const Text('Member Since'),
              subtitle: Text(
                DateFormat('MMMM dd, yyyy').format(user.createdAt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assigned Organizations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _manageShops(context),
                icon: const Icon(Icons.settings),
                label: const Text('Manage'),
              ),
            ],
          ),

          // --- NEW STREAM BUILDER ---
          StreamBuilder<List<OrganizationSnapshot>>(
            stream: _userService.getUserShops(
              user.id,
            ), // Listen for live updates
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LinearProgressIndicator());
              }

              final assignedShops = snapshot.data ?? [];

              if (assignedShops.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No shops assigned yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assignedShops.length,
                itemBuilder: (context, index) {
                  final shop = assignedShops[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(
                          int.parse(shop.accentColor.replaceAll('#', '0xFF')),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        shop.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('ID: ${shop.orgId}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        // 1. Show a quick "Loading..." feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening shop details...'),
                            duration: Duration(milliseconds: 500),
                          ),
                        );

                        try {
                          // 2. Fetch the "Heavy" Organization object
                          final Organization? fullOrg =
                              await _organizationService.getOrganizationById(
                                shop.orgId,
                              );

                          if (fullOrg != null && context.mounted) {
                            // 3. Navigate with the complete object
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrganizationDetailsScreen(org: fullOrg),
                              ),
                            );
                          } else {
                            throw 'Shop details not found';
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return TextButton(
      onPressed: () => _confirmDelete(context),
      child: const Text('Deactivate User', style: TextStyle(color: Colors.red)),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormScreen(user: user, mode: FormMode.edit),
      ),
    );
  }

  void _manageShops(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Allows it to take more height if you have many shops
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ShopAssignmentPicker(user: user),
    );
  }

  void _confirmDelete(BuildContext context) {
    // Show confirmation dialog before deleting
  }
}
