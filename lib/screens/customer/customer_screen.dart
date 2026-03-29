import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomersScreen extends StatefulWidget {
  final String orgId;

  const CustomersScreen({super.key, required this.orgId});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('organizations')
            .doc(widget.orgId)
            .collection('customers')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          // Client-side filtering for high-speed search
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final phone = (data['phone'] ?? '').toString();
            return name.contains(_searchQuery) || phone.contains(_searchQuery);
          }).toList();

          if (docs.isEmpty)
            return const Center(child: Text('No customers found.'));

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final customer = docs[index].data() as Map<String, dynamic>;
              final String customerId = docs[index].id;

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
                      (customer['name'] != null &&
                              customer['name'].toString().isNotEmpty)
                          ? customer['name'][0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    customer['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(customer['phone']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.phone_outlined,
                          color: Colors.blue,
                        ),
                        onPressed: () =>
                            launchUrl(Uri.parse("tel:${customer['phone']}")),
                      ),
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.teal),
                        onPressed: () => _viewPurchaseHistory(
                          customerId,
                          customer['name'],
                          customer['phone'],
                        ),
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

  void _viewPurchaseHistory(
    String customerId,
    String customerName,
    String customerPhone,
  ) {
    Navigator.pushNamed(
      context,
      '/customer-sales-history',
      arguments: {
        'orgId': widget.orgId,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
      },
    );
  }

  void _showCustomerDetails(Map<String, dynamic> customer) {
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
              customer['name'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              customer['phone'],
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
                  '${customer['visitCount'] ?? 1}',
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
