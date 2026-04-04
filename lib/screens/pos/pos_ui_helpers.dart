import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/screens/pos/category_card.dart';
import 'package:apoorva_app/screens/pos/item_price_calculator.dart';
import 'package:flutter/material.dart';
import 'pos_provider.dart';

class PosUIHelpers {
  // 1. SMART CALCULATOR (Price & Discount Input)
  static void openCalculator(
    BuildContext context,
    PosProvider provider, {
    Category? category,
    CartItem? existingItem,
    int? index,
  }) {
    final currentCategory = existingItem?.category ?? category;
    if (currentCategory == null) {
      debugPrint('openCalculator called without category or existingItem');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ItemPriceCalculator(
        provider: provider,
        category: existingItem?.category ?? category,
        existingItem: existingItem,
        index: index,
      ),
    );
  }

  // 2. CATEGORY PICKER (Searchable List)
  static void showCategoryPicker(
    BuildContext context,
    PosProvider provider,
    List<Category> categories,
  ) {
    final parentContext = context;

    String searchQuery = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = categories
              .where(
                (c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setModalState(() => searchQuery = val),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text("No categories found"))
                      : GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) => CategoryCard(
                            category: filtered[idx],
                            onTap: () {
                              Navigator.pop(context);
                              if (!parentContext.mounted) return;
                              openCalculator(
                                parentContext,
                                provider,
                                category: filtered[idx],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
