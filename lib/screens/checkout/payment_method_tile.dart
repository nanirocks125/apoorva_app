// --- PAYMENT METHOD TILE ---
import 'package:apoorva_app/enum/payment_mode.dart';
import 'package:flutter/material.dart';

class PaymentMethodTile extends StatelessWidget {
  final PaymentMode mode;
  final bool isSelected;
  final TextEditingController controller;
  final Function(bool) onToggle;
  final VoidCallback onChanged;

  const PaymentMethodTile({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.controller,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            title: Text(
              mode.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            value: isSelected,
            onChanged: (val) => onToggle(val ?? false),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
