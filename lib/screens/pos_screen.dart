import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:flutter/material.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key, required this.orgId});
  final String orgId;

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // PRD ప్రకారం కేటగిరీల జాబితా [cite: 8, 31]
  // final List<String> categories = [
  //   'Bangles',
  //   'Panchaloha',
  //   'Necklace',
  //   'Earrings',
  //   'Sets',
  // ];

  OrganizationService get _orgService => OrganizationService();
  final PosCart _cart = PosCart();

  void _openSmartCalculator(Map<String, dynamic> category) {
    final TextEditingController priceController = TextEditingController();
    double selectedDiscount = 0.0;

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
                'Adding ${category['name']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText:
                      'Sticker Price', // As per comfort reference [cite: 25]
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              // Discount Quick-Keys
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
                ),
                onPressed: () {
                  final double? price = double.tryParse(priceController.text);
                  if (price != null && price > 0) {
                    _updateCart(() {
                      _cart.items.add(
                        CartItem(
                          categoryId: category['id'],
                          categoryName: category['name'],
                          stickerPrice: price,
                          discountPercent: selectedDiscount,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('ADD TO CART'),
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
          // --- VISUAL DASHBOARD ---
          // PosScreen build method లోపల
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _orgService.getLiveCategories(widget.orgId),
              builder: (context, snapshot) {
                print('error ${snapshot.error}');
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data ?? [];

                if (categories.isEmpty) {
                  return const Center(
                    child: Text('No categories found. Add some in Inventory!'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
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
                      // () => {},
                      // () => _openSmartCalculator(
                      //   cat,
                      // ), // బల్క్ కేటగిరీ లెవెల్ ట్రాకింగ్ [cite: 8]
                    );
                  },
                );
              },
            ),
          ),

          // --- CART & CHECKOUT ---
          _buildCartSummary(),
        ],
      ),
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
                : () {
                    // TODO: Navigate to Tender Splitting Screen
                  },
            child: const Text(
              'CHECKOUT',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildCategoryButton(String label) {
  //   return InkWell(
  //     onTap: () => _openSmartCalculator(label),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         color: Colors.orange.withOpacity(0.1),
  //         borderRadius: BorderRadius.circular(16),
  //         border: Border.all(color: Colors.orange),
  //       ),
  //       child: Center(
  //         child: Text(
  //           label,
  //           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
