import 'package:apoorva_app/model/organization.dart';
import 'package:apoorva_app/screens/organization_details_screen.dart';
import 'package:apoorva_app/screens/organization_form_screen.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:flutter/material.dart';

class OrganizationScreen extends StatelessWidget {
  final OrganizationService _orgService = OrganizationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Management'),
        backgroundColor: const Color(0xFFFF5733),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF5733),
        onPressed: () => _openOrgForm(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Organization>>(
        stream: _orgService.getOrganizations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orgs = snapshot.data!;

          if (orgs.isEmpty) {
            return const Center(child: Text('No organizations available'));
          }

          return ListView.builder(
            itemCount: orgs.length,
            itemBuilder: (context, index) {
              final org = orgs[index]; // 'org' is now an Organization object!
              final bool isActive = org.status == 'Active';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    org.name, // Changed from org['org_name']
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Status: ${org.status}',
                  ), // Changed from org['status']
                  onTap: () =>
                      _viewOrgDetails(context, org), // Pass the object directly
                  onLongPress: () => _openOrgForm(context, org: org),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isActive,
                        activeColor: const Color(0xFFFF5733),
                        onChanged: (_) =>
                            _orgService.toggleStatus(org.id!, org.status),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(context, org.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openOrgForm(BuildContext context, {Organization? org}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrganizationFormScreen(
          org: org,
          mode: org == null ? FormMode.create : FormMode.edit,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String orgId) {
    // Audit-friendly confirmation dialog to protect shop data
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Organization?'),
          content: const Text(
            'This will permanently remove the shop and its data. '
            'It is recommended to use the "Inactive" toggle instead to preserve the audit trail.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                await _orgService.deleteOrganization(orgId);
                if (context.mounted) Navigator.pop(context);

                // Show confirmation snackbar
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Organization deleted successfully'),
                    ),
                  );
                }
              },
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  void _viewOrgDetails(BuildContext context, Organization org) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrganizationDetailsScreen(org: org),
      ),
    );
  }
}
