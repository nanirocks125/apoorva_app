import 'package:apoorva_app/screens/pos/cart_item_tile.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/screens/pos/pos_ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class CartListSection extends StatelessWidget {
  const CartListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PosProvider>(context);

    // 1. EMPTY STATE LOGIC (SliverFillRemaining is correct here)
    if (provider.cart.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'lib/assets/animations/empty_cart.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
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

    // 2. DATA STATE (Returning a list of Slivers using a Fragment or SliverMainAxisGroup)
    // Note: If calling this from CustomScrollView(slivers: [CartListSection()]),
    // it's better to use a multi-sliver wrapper if your version supports it,
    // or return the slivers as a list if handled by the parent.

    return SliverMainAxisGroup(
      // 🚀 Column కి బదులు ఇది వాడాలి
      slivers: [
        // HEADER SECTION
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "CURRENT CART",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueGrey.shade600,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${provider.cart.items.length} ITEMS",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // LIST SECTION
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = provider.cart.items[index];
            return CartItemTile(
              item: item,
              onTap: () => PosUIHelpers.openCalculator(
                context,
                provider,
                existingItem: item,
                index: index,
              ),
              onRemove: () => provider.removeItem(index),
            );
          }, childCount: provider.cart.items.length),
        ),
      ],
    );
  }
}
