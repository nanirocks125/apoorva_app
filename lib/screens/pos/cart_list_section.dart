import 'package:apoorva_app/screens/pos/cart_item_tile.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CartListSection extends StatelessWidget {
  const CartListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PosProvider>(context);

    if (provider.cart.items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Text("Cart is empty")),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = provider.cart.items[index];
        return CartItemTile(
          // మీరు ఆల్రెడీ రాసిన ఆ Stateless Widget
          item: item,
          onTap: () => {}, // logic here
          onRemove: () => provider.removeItem(index),
        );
      }, childCount: provider.cart.items.length),
    );
  }
}
