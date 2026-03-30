import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/cart/draft_cart.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/screens/checkout_screen.dart';
import 'package:apoorva_app/services/draft_cart_service.dart';
import 'package:apoorva_app/services/draft_service.dart';
import 'package:apoorva_app/services/organization_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key, required this.organization});
  final Organization organization;

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  OrganizationService get _orgService => OrganizationService();
  final PosCart _cart = PosCart();
  String?
  _activeDraftId; // Tracks if the current cart came from a specific draft
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apoorva POS'),
        actions: [
          // 1. డ్రాఫ్ట్ గా సేవ్ చేసే బటన్
          IconButton(
            icon: const Icon(
              Icons.pause_circle_filled_outlined,
              color: Colors.orange,
            ),
            tooltip: 'Hold Bill',
            onPressed: _cart.items.isEmpty ? null : _holdCurrentBill,
          ),
          // 2. డ్రాఫ్ట్స్ లిస్ట్ చూసే బటన్ (With Badge)
          StreamBuilder<List<DraftCart>>(
            stream: DraftCartService().getDraftsStream(widget.organization.id),
            builder: (context, snapshot) {
              int count = snapshot.hasData ? snapshot.data!.length : 0;
              return Badge(
                label: Text(count.toString()),
                child: IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: () =>
                      _showDraftsList(context, snapshot.data ?? []),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
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
    return StreamBuilder<List<Category>>(
      stream: _orgService.getLiveCategories(widget.organization.id),
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
              cat,
              () =>
                  _openSmartCalculator(category: cat), // Named parameter వాడాలి
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Category category,
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
            color: category.isHotkey
                ? const Color(0xFFFF5733)
                : Colors.grey.shade200,
            width: category.isHotkey ? 2 : 1, // హాట్-కీ అయితే హైలైట్ అవుతుంది
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
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${category.currentStock}',
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
            onTap: () => _openSmartCalculator(existingItem: item, index: index),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 1. Visual Icon/Letter Badge
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFF5733).withOpacity(0.1),
                    child: Text(
                      item.category.name
                          .substring(0, 1)
                          .toUpperCase(), // First letter only
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
                          item.category.name,
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
                            orgId: widget.organization.id,
                            customer: Customer(
                              name: _customerNameController.text,
                              phone: _customerPhoneController.text,
                              createdAt: DateTime.now(),
                            ),
                            activeDraftId: _activeDraftId,
                          ),
                        ),
                      ).then((sold) {
                        if (sold == true) {
                          // 1. If it was a resumed draft, delete it now that payment is confirmed
                          if (_activeDraftId != null) {
                            DraftService().deleteDraft(
                              widget.organization.id,
                              _activeDraftId!,
                            );
                          }

                          // 2. Clear state for the next customer
                          _updateCart(() {
                            _activeDraftId = null;
                            _cart.items.clear();
                            _customerNameController.clear();
                            _customerPhoneController.clear();
                          });
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

  // 1. ప్రస్తుత బిల్లును హోల్డ్ చేయడం
  Future<void> _holdCurrentBill() async {
    await DraftService().saveDraft(
      orgId: widget.organization.id,
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      items: _cart.items,
      // Pass the activeDraftId here if you want to overwrite instead of creating a new one
    );

    _updateCart(() {
      _activeDraftId = null; // Reset
      _cart.items.clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
    });
  }

  // 2. హోల్డ్ లో ఉన్న బిల్లుల లిస్ట్ చూపించడం
  void _showDraftsList(BuildContext context, List<DraftCart> drafts) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'HOLD BILLS (DRAFTS)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: drafts.isEmpty
                  ? const Center(child: Text("No bills on hold"))
                  : ListView.builder(
                      itemCount: drafts.length,
                      itemBuilder: (context, index) {
                        final draftCart = drafts[index];
                        return ListTile(
                          title: Text(
                            draftCart.customerName.isEmpty
                                ? "Walk-in"
                                : draftCart.customerName,
                          ),
                          subtitle: Text(
                            "${draftCart.items.length} items • ₹${draftCart.total}",
                          ),
                          trailing: const Icon(
                            Icons.play_arrow,
                            color: Colors.green,
                          ),
                          onTap: () {
                            _resumeDraft(drafts[index].id, draftCart);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. డ్రాఫ్ట్ ని మళ్ళీ కార్ట్ లోకి తీసుకురావడం
  void _resumeDraft(String draftId, DraftCart draftCart) {
    _updateCart(() {
      _activeDraftId = draftId;
      _cart.items.clear();
      _customerNameController.text = draftCart.customerName;
      _customerPhoneController.text = draftCart.customerPhone;

      for (var item in draftCart.items) {
        // ఇక్కడ Category ఆబ్జెక్ట్ ని క్రియేట్ చేయాలి (లేదా సర్వీస్ నుండి ఫెచ్ చేయాలి)
        // ప్రస్తుతానికి డమ్మీ ఐడి తో క్రియేట్ చేస్తున్నాను
        final categoryStub = Category(
          id: item.category.id,
          name: item.category.name,
          currentStock: 0,
          isHotkey: false,
          billMachineNumber: 0,
        );

        _cart.items.add(
          CartItem(
            category: categoryStub,
            stickerPrice: item.stickerPrice,
            discountPercent: item.discountPercent,
          ),
        );
      }
    });
  }

  // 1. Named parameters వాడటం వల్ల కోడ్ క్లీన్ గా ఉంటుంది
  void _openSmartCalculator({
    Category? category,
    CartItem? existingItem,
    int? index,
  }) {
    // ఎడిట్ చేస్తుంటే పాత ప్రైస్, లేకపోతే ఖాళీ
    final TextEditingController priceController = TextEditingController(
      text: existingItem != null
          ? existingItem.stickerPrice.toStringAsFixed(0)
          : '',
    );

    double selectedDiscount = existingItem?.discountPercent ?? 0.0;

    // కేటగిరీ ఆబ్జెక్ట్ ని ఎంచుకోవడం
    final currentCategory = existingItem?.category ?? category;

    if (currentCategory == null) return; // Safety check

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
                    ? 'Edit ${currentCategory.name}'
                    : 'Adding ${currentCategory.name}',
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
              // ... (Discount Selection Row) ...
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final double? price = double.tryParse(priceController.text);
                  if (price != null && price > 0) {
                    _updateCart(() {
                      final updatedItem = CartItem(
                        category: currentCategory, // Correct Category Object
                        stickerPrice: price,
                        discountPercent: selectedDiscount,
                      );

                      if (index != null) {
                        _cart.items[index] = updatedItem;
                      } else {
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
}
