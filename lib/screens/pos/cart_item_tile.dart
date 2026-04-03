import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:flutter/material.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onTap; // ఇది Edit కోసం వాడతాం
  final VoidCallback onRemove; // ఇది Delete కోసం

  const CartItemTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onRemove,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      // 1. Margin తగ్గించడం వల్ల ఐటమ్స్ మధ్య గ్యాప్ తగ్గుతుంది
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        // 2. IS DENSE: ఇది ListTile హైట్‌ని గణనీయంగా తగ్గిస్తుంది
        // isDense: true,
        // 3. VISUAL DENSITY: ప్యాడింగ్‌ని ఇంకా కంప్రెస్ చేయడానికి
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),

        leading: CircleAvatar(
          radius: 18, // 22 నుండి 18 కి తగ్గించాం
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: Text(
            item.category.name[0],
            style: const TextStyle(
              color: Color(0xFFFF5733),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          item.category.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14, // 15 నుండి 14 కి
            color: Color(0xFF2D3436),
          ),
        ),
        subtitle: Text(
          '₹${item.mrp} • ${item.discountPercent.toInt()}% Off',
          style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${item.finalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15, // 17 నుండి 15 కి
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onRemove,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              icon: const Icon(
                Icons.remove_circle_outline_rounded,
                color: Colors.redAccent,
                size: 20, // 24 నుండి 20 కి
              ),
            ),
          ],
        ),
      ),
    );
  }
}
