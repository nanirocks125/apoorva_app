import 'package:apoorva_app/model/customer/customer.dart';
import 'package:flutter/material.dart';

class CustomerSearchOverlay extends StatelessWidget {
  final List<Customer> customers;
  final Function(Customer) onSelected;

  const CustomerSearchOverlay({
    super.key,
    required this.customers,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(8),
        itemCount: customers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = customers[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person, size: 20)),
            title: Text(
              c.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(c.phone),
            onTap: () => onSelected(c),
          );
        },
      ),
    );
  }
}
