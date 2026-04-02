import 'package:apoorva_app/screens/pos/cart_item_tile.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CartListSection extends StatelessWidget {
  const CartListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PosProvider>(context);

    // EMPTY STATE LOGIC
    if (provider.cart.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false, // Scroll అవసరం లేదు కాబట్టి
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. LOTTIE ANIMATION
              Lottie.asset(
                'lib/assets/animations/empty_cart.json', // మీ యానిమేషన్ పాత్
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              // 2. TEXT FEEDBACK
              Text(
                "Your cart is empty",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Add some items to start billing",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = provider.cart.items[index];
        return CartItemTile(
          item: item,
          // TODO: open edit modal
          onTap: () => {}, // logic here
          onRemove: () => provider.removeItem(index),
        );
      }, childCount: provider.cart.items.length),
    );
  }
}
