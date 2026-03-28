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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _orgService.getOrganizations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading shops: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orgs = snapshot.data!;

          // Explicit check for empty organizations list
          if (orgs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No organizations available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Tap the + button to create your first shop',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: orgs.length,
            itemBuilder: (context, index) {
              final org = orgs[index];
              final bool isActive = org['status'] == 'Active'; // [cite: 120]

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    org['org_name'], // [cite: 98]
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Status: ${org['status']}'), // [cite: 120]
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Active/Inactive Toggle for Security
                      Switch(
                        value: isActive,
                        activeColor: const Color(0xFFFF5733),
                        onChanged: (_) =>
                            _orgService.toggleStatus(org['id'], org['status']),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(context, org['id']),
                      ),
                    ],
                  ),
                  onLongPress: () => _openOrgForm(context, org: org),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openOrgForm(BuildContext context, {Map<String, dynamic>? org}) {
    // Navigates to the Form screen for Create or Update
  }

  void _confirmDelete(BuildContext context, String orgId) {
    // Navigates to the Form screen for Create or Update
  }
}
