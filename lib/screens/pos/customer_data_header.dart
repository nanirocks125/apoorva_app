import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomerDataHeader extends StatelessWidget {
  const CustomerDataHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PosProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: provider.nameController, // Provider నుండి వస్తుంది
              decoration: const InputDecoration(
                hintText: 'Customer Name',
                prefixIcon: Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: TextField(
              controller: provider.phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Phone',
                prefixIcon: Icon(Icons.phone_iphone_outlined),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
