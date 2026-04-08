import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/services/customer_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final organization = Provider.of<OrganizationProvider>(
      context,
    ).currentOrganization;

    // if (organization == null) {
    //   return Text('No organization selected');
    // }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Directory'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: (organization == null)
          ? Text('No organization selected')
          : StreamBuilder<List<Customer>>(
              stream: CustomerService().getCustomers(organization.id),
              builder: (context, snapshot) {
                print(
                  'no of customers in stream: ${snapshot.data?.length ?? 0}',
                );
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 1. Client-side filtering using typed Model properties
                final filteredCustomers = snapshot.data!.where((customer) {
                  final query = _searchQuery.toLowerCase();
                  return customer.name.toLowerCase().contains(query) ||
                      customer.phone.contains(query);
                }).toList();

                if (filteredCustomers.isEmpty) {
                  return const Center(child: Text('No customers found.'));
                }

                return ListView.builder(
                  itemCount: filteredCustomers.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Text(
                            // Safety check: if name is empty, show '?' instead of crashing
                            (customer.name.isNotEmpty)
                                ? customer.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(customer.phone),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.phone_outlined,
                                color: Colors.blue,
                              ),
                              onPressed: () =>
                                  launchUrl(Uri.parse("tel:${customer.phone}")),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.history,
                                color: Colors.teal,
                              ),
                              onPressed: () =>
                                  _viewPurchaseHistory(customer, organization),
                            ),
                          ],
                        ),
                        onTap: () => _showCustomerDetails(customer),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _viewPurchaseHistory(Customer customer, Organization org) {
    Navigator.pushNamed(
      context,
      '/customer-sales-history',
      arguments: {'orgId': org.id, 'customer': customer},
    );
  }

  void _showCustomerDetails(Customer customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              customer.phone,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const Divider(height: 32),
            const Text(
              'Customer Insights',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Example Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Visits:'),
                Text(
                  '${customer.visitCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/scripts', arguments: customer),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Send Marketing Script'),
            ),
          ],
        ),
      ),
    );
  }
}
