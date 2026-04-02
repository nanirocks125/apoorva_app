import 'package:apoorva_app/screens/pos/category_card.dart';
import 'package:flutter/material.dart';
import '../../model/category/category.dart';
import '../../model/cart/cart_item.dart';
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
    final TextEditingController priceController = TextEditingController(
      text: existingItem != null
          ? existingItem.stickerPrice.toStringAsFixed(0)
          : '',
    );
    double selectedDiscount = existingItem?.discountPercent ?? 0.0;
    final currentCategory = existingItem?.category ?? category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                existingItem != null
                    ? 'Edit ${currentCategory?.name}'
                    : 'Adding ${currentCategory?.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Sticker Price',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
                onChanged: (_) => setModalState(
                  () {},
                ), // ధర మారుతున్నప్పుడు రియల్ టైమ్ అప్‌డేట్
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Select Discount",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              // DISCOUNT CHIPS
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [0.0, 5.0, 10.0, 15.0, 20.0, 25.0].map((pct) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('${pct.toInt()}%'),
                        selected: selectedDiscount == pct,
                        selectedColor: const Color(0xFFFF5733).withOpacity(0.2),
                        onSelected: (selected) =>
                            setModalState(() => selectedDiscount = pct),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 32),
              // FINAL PRICE PREVIEW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Final Price:",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Builder(
                    builder: (context) {
                      final double price =
                          double.tryParse(priceController.text) ?? 0.0;
                      final double finalPrice =
                          price * (1 - (selectedDiscount / 100));
                      return Text(
                        '₹${finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5733),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFFFF5733),
                ),
                onPressed: () {
                  final double? price = double.tryParse(priceController.text);
                  if (price != null && price > 0) {
                    final newItem = CartItem(
                      category: currentCategory!,
                      stickerPrice: price,
                      discountPercent: selectedDiscount,
                    );
                    if (index != null) {
                      provider.updateItem(index, newItem);
                    } else {
                      provider.addItem(newItem);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  existingItem != null ? 'UPDATE ITEM' : 'ADD TO CART',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 2. CATEGORY PICKER (Searchable List)
  static void showCategoryPicker(
    BuildContext context,
    PosProvider provider,
    List<Category> categories,
  ) {
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
                              openCalculator(
                                context,
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
