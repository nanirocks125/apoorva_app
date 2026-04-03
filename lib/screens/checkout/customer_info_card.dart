// --- CUSTOMER INFO CARD ---
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:flutter/material.dart';

class CustomerInfoCard extends StatelessWidget {
  final Customer customer;
  const CustomerInfoCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5733).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customer.name.isEmpty ? 'Walk-in Customer' : customer.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            customer.phone.isEmpty ? 'No Phone' : customer.phone,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
