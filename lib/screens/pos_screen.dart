import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:apoorva_app/screens/checkout_screen.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key, required this.orgId});
  final String orgId;

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  OrganizationService get _orgService => OrganizationService();
  final PosCart _cart = PosCart();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  void _openSmartCalculator(
    Map<String, dynamic> category, {
    CartItem? existingItem,
    int? index,
  }) {
    // If editing, use the existing price; otherwise, start empty
    final TextEditingController priceController = TextEditingController(
      text: existingItem != null
          ? existingItem.stickerPrice.toStringAsFixed(0)
          : '',
    );

    double selectedDiscount = existingItem?.discountPercent ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                    ? 'Edit ${category['name']}'
                    : 'Adding ${category['name']}',
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
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [0.0, 5.0, 10.0, 15.0]
                    .map(
                      (pct) => ChoiceChip(
                        label: Text('${pct.toInt()}% Off'),
                        selected: selectedDiscount == pct,
                        onSelected: (selected) =>
                            setModalState(() => selectedDiscount = pct),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: existingItem != null
                      ? Colors.blue
                      : const Color(0xFFFF5733),
                ),
                onPressed: () {
                  final double? price = double.tryParse(priceController.text);
                  if (price != null && price > 0) {
                    _updateCart(() {
                      final updatedItem = CartItem(
                        categoryId: category['id'],
                        categoryName: category['name'],
                        stickerPrice: price,
                        discountPercent: selectedDiscount,
                      );

                      if (index != null) {
                        // UPDATE: Replace existing item at index
                        _cart.items[index] = updatedItem;
                      } else {
                        // CREATE: Add new item
                        _cart.items.add(updatedItem);
                      }
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  existingItem != null ? 'UPDATE ITEM' : 'ADD TO CART',
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to refresh UI
  void _updateCart(VoidCallback fn) {
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apoorva POS')),
      body: Column(
        children: [
          // 1. CUSTOMER INPUT: Priority placement at the top
          _buildCustomerDataHeader(),

          const Divider(height: 1),
          // 1. VISUAL DASHBOARD: Now shrinks to fit content [cite: 36]
          _buildCategoryGrid(),

          const Divider(height: 1, thickness: 1),

          // 2. CURRENT CART: Header [cite: 36]
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: Text(
              'CURRENT CART',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
                letterSpacing: 1.1,
              ),
            ),
          ),

          // 3. CART LIST: Takes the REMAINING space [cite: 36]
          Expanded(child: _buildCartList()),

          // 4. CART SUMMARY & CHECKOUT [cite: 36]
          _buildCartSummary(),
        ],
      ),
    );
  }

  Widget _buildCustomerDataHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // 1. Customer Name Field
          TextField(
            controller: _customerNameController,
            decoration: InputDecoration(
              labelText: 'Customer Name',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.person_outline, size: 20),
            ),
          ),

          const SizedBox(height: 12), // Vertical gap instead of horizontal
          // 2. Phone Number Field
          TextField(
            controller: _customerPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _orgService.getLiveCategories(widget.orgId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const Center(child: Text('No categories found.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          // --- THE KEY FIXES ---
          shrinkWrap: true, // Sizes the grid to its children only
          physics:
              const NeverScrollableScrollPhysics(), // Let the Column handle layout
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140, // Slightly smaller for a tighter look
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3, // Wider than tall for a "button" feel
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return _buildCategoryCard(
              context,
              cat['name'],
              cat['current_stock'].toString(),
              cat['is_hotkey'] ?? false,
              cat['social_media_link'],
              () => _openSmartCalculator(cat),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String name,
    String stock,
    bool isHotkey,
    String? socialLink,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHotkey ? const Color(0xFFFF5733) : Colors.grey.shade200,
            width: isHotkey ? 2 : 1, // హాట్-కీ అయితే హైలైట్ అవుతుంది
          ),
        ),
        child: Stack(
          children: [
            // Social Media Link Icon
            // if (socialLink != null && socialLink.isNotEmpty)
            //   Positioned(
            //     top: 8,
            //     right: 8,
            //     child: IconButton(
            //       icon: const Icon(
            //         Icons.instagram,
            //         color: Colors.pink,
            //         size: 20,
            //       ),
            //       onPressed: () =>
            //           _launchURL(socialLink), // Social Media Link Mapper
            //     ),
            //   ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: $stock',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList() {
    if (_cart.items.isEmpty) {
      return const Center(
        child: Text('Cart is empty', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _cart.items.length,
      itemBuilder: (context, index) {
        final item = _cart.items[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            // --- Reuse the Smart Calculator for Editing ---
            onTap: () => _openSmartCalculator(
              {'id': item.categoryId, 'name': item.categoryName},
              existingItem: item,
              index: index,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 1. Visual Icon/Letter Badge
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFF5733).withOpacity(0.1),
                    child: Text(
                      item.categoryName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFFF5733),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 2. Item Details (Name & Discount math)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.categoryName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${item.stickerPrice.toStringAsFixed(0)} • ${item.discountPercent.toInt()}% Off',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Price & Action
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${item.finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () =>
                            _updateCart(() => _cart.items.removeAt(index)),
                        child: Icon(
                          Icons.remove_circle,
                          color: Colors.red.shade400,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items: ${_cart.items.length}',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                'Total: ₹${_cart.totalPayable.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: _cart.items.isEmpty ? Colors.grey : Colors.green,
            ),
            onPressed: _cart.items.isEmpty
                ? null
                : () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(
                            cart: _cart,
                            orgId: widget.orgId,
                            customerName: _customerNameController.value.text,
                            customerPhone: _customerPhoneController.value.text,
                          ),
                        ),
                      ).then((sold) {
                        if (sold == true) {
                          _updateCart(() => _cart.items.clear());
                        }
                      }),
            child: const Text(
              'CHECKOUT',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
