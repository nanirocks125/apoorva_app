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
          // Wrap everything except the footer in an Expanded + CustomScrollView
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 1. Customer Fields
                SliverToBoxAdapter(child: _buildCustomerDataHeader()),

                const SliverToBoxAdapter(
                  child: Divider(height: 1),
                ), // Replace the old grid with the new Row
                _buildHotKeyRow(),

                // 2. The Category Grid
                // We wrap your grid in a SliverToBoxAdapter so it stays
                // as part of the main scroll flow.
                // SliverToBoxAdapter(child: _buildCategoryGrid()),
                const SliverToBoxAdapter(
                  child: Divider(height: 1, thickness: 1),
                ),

                // 3. Cart Header
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                ),

                // 4. The Cart List
                // We convert your ListView into a SliverList
                _buildSliverCartList(),
              ],
            ),
          ),

          // 5. Fixed Bottom Summary
          _buildCartSummary(),
        ],
      ),
    );
  }

  Widget _buildSliverCartList() {
    if (_cart.items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text(
                'Cart is empty',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList.builder(
        itemCount: _cart.items.length,
        itemBuilder: (context, index) {
          final item = _cart.items[index];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade100),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              // Tapping an item opens the calculator to edit price/discount
              onTap: () =>
                  _openSmartCalculator(existingItem: item, index: index),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // 1. Icon Badge
                    CircleAvatar(
                      backgroundColor: const Color(
                        0xFFFF5733,
                      ).withOpacity(0.08),
                      child: Text(
                        item.category.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFFF5733),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 2. Item Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.category.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${item.stickerPrice.toStringAsFixed(0)} • ${item.discountPercent.toInt()}% Off',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Price & Remove Action
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${item.finalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () =>
                              _updateCart(() => _cart.items.removeAt(index)),
                          child: Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red.shade300,
                            size: 20,
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
      ),
    );
  }

  Widget _buildCustomerDataHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _customerNameController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Customer Name',
                prefixIcon: const Icon(Icons.person_outline, size: 18),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: TextField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Phone',
                prefixIcon: const Icon(Icons.phone_iphone_outlined, size: 18),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
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
    final bool isHotkey = category.isHotkey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isHotkey
                ? const Color(0xFFFF5733).withOpacity(0.5)
                : Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Hotkey indicator bar
              if (isHotkey)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(height: 3, color: const Color(0xFFFF5733)),
                ),

              // Bill Number Badge (Top-Left)
              Positioned(
                top: 6,
                left: 8,
                child: Text(
                  '#${category.billMachineNumber}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),

              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14, // Reduced size to prevent overflow
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'STK: ${category.currentStock}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_cart.items.length} ITEMS',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${_cart.totalPayable.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(
                  0xFF00B894,
                ), // Clean Professional Green
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _cart.items.isEmpty
                  ? null
                  : () => _navigateToCheckout(),
              child: const Text(
                'PROCEED TO CHECKOUT',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
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

  void _openSmartCalculator({
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
                ), // ధర మారుతున్నప్పుడు కింద అమౌంట్ అప్‌డేట్ అవుతుంది
              ),
              const SizedBox(height: 16),

              // --- 1. DISCOUNT CHIPS (తిరిగి వచ్చేసాయి!) ---
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Select Discount",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [0.0, 5.0, 10.0, 15.0, 20.0].map((pct) {
                  return ChoiceChip(
                    label: Text('${pct.toInt()}%'),
                    selected: selectedDiscount == pct,
                    selectedColor: const Color(0xFFFF5733).withOpacity(0.2),
                    onSelected: (selected) {
                      // చిప్ క్లిక్ చేసినప్పుడు డిస్కౌంట్ మారుతుంది + ఫైనల్ ప్రైస్ కూడా అప్‌డేట్ అవుతుంది
                      setModalState(() => selectedDiscount = pct);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              const Divider(),

              // --- 2. FINAL PRICE PREVIEW (రియల్ టైమ్) ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
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
                        // డిస్కౌంట్ తర్వాత వచ్చే అసలు ధర
                        final double finalPrice =
                            price * (1 - (selectedDiscount / 100));
                        return Text(
                          '₹${finalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF5733),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFFFF5733),
                ),
                onPressed: () {
                  final double? price = double.tryParse(priceController.text);
                  if (price != null && price > 0) {
                    _updateCart(() {
                      final updatedItem = CartItem(
                        category: currentCategory!,
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

  // Helper to refresh UI
  void _updateCart(VoidCallback fn) {
    setState(fn);
  }

  Widget _buildHotKeyRow() {
    return StreamBuilder<List<Category>>(
      stream: _orgService.getLiveCategories(widget.organization.id),
      builder: (context, snapshot) {
        // FIX: Even the "loading" or "empty" states must return a Sliver
        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final allCategories = snapshot.data ?? [];
        final hotkeys = allCategories.where((c) => c.isHotkey).toList();

        // FIX: Wrap the horizontal row in a SliverToBoxAdapter
        return SliverToBoxAdapter(
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: hotkeys.length + 1,
              itemBuilder: (context, index) {
                if (index < hotkeys.length) {
                  final cat = hotkeys[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 120,
                      child: _buildCategoryCard(
                        context,
                        cat,
                        () => _openSmartCalculator(category: cat),
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildMoreButton(context, allCategories),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showAllCategoriesPicker(
    BuildContext context,
    List<Category> categories,
  ) {
    String searchQuery = ""; // Local search state

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Filter categories based on search query
          final filteredCategories = categories
              .where(
                (c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()),
              )
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.8, // Slightly larger to accommodate search bar
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                // 1. Search Bar Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search categories...',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          // Update the local state of the bottom sheet
                          setModalState(() => searchQuery = value);
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // 2. Results Grid
                Expanded(
                  child: filteredCategories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No categories match "$searchQuery"',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.1,
                              ),
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final cat = filteredCategories[index];
                            return _buildCategoryCard(context, cat, () {
                              Navigator.pop(context); // Close picker
                              _openSmartCalculator(
                                category: cat,
                              ); // Open calculator
                            });
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context, List<Category> allCategories) {
    return InkWell(
      onTap: () => _showAllCategoriesPicker(context, allCategories),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_view_rounded, color: Colors.blueGrey),
            SizedBox(height: 4),
            Text('More', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _navigateToCheckout() {
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
          DraftService().deleteDraft(widget.organization.id, _activeDraftId!);
        }

        // 2. Clear state for the next customer
        _updateCart(() {
          _activeDraftId = null;
          _cart.items.clear();
          _customerNameController.clear();
          _customerPhoneController.clear();
        });
      }
    });
  }
}
