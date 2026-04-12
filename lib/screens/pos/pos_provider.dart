import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/model/sale.dart';
import 'package:flutter/material.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:apoorva_app/model/cart/draft_cart.dart';
import 'package:apoorva_app/services/draft_cart_service.dart';

class PosProvider extends ChangeNotifier {
  final String orgId;
  PosCart cart = PosCart();
  String? activeDraftId;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  PosProvider({required this.orgId, Sale? initialSale}) {
    if (initialSale != null) {
      _loadFromSale(initialSale);
    }
  }

  void addItem(CartItem item) {
    cart.items.add(item);
    notifyListeners();
  }

  void removeItem(int index) {
    // Guard index-based cart mutations to avoid RangeError
    if (index < 0 || index >= cart.items.length) return;

    cart.items.removeAt(index);
    notifyListeners();
  }

  void updateItem(CartItem updatedItem, int index) {
    // Guard index-based cart mutations to avoid RangeError

    if (index < 0 || index >= cart.items.length) return;

    cart.items[index] = updatedItem;
    notifyListeners();
  }

  Future<void> holdCurrentBill() async {
    if (cart.items.isEmpty) return;

    try {
      await DraftCartService().saveDraft(
        orgId,
        DraftCart(
          id: activeDraftId ?? '',
          customerName: nameController.text,
          customerPhone: phoneController.text,
          items: List.from(cart.items),
          total: cart.totalPayable,
          createdAt: DateTime.now(),
        ),
      );
      clearCart();
    } catch (e) {
      debugPrint('Failed to save draft: $e');
      // Optionally rethrow or notify UI
      rethrow;
    }
  }

  void resumeDraft(String draftId, DraftCart draft) {
    activeDraftId = draftId;
    nameController.text = draft.customerName;
    phoneController.text = draft.customerPhone;
    cart.items.clear();
    cart.items.addAll(draft.items);
    notifyListeners();
  }

  void clearCart() {
    activeDraftId = null;
    cart.items.clear();
    nameController.clear();
    phoneController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _loadFromSale(Sale sale) {
    // 1. Map Sale Items back to CartItems
    final restoredItems = sale.items.map((item) {
      return CartItem(
        category: Category(
          id: item.categoryId,
          name: item.categoryName,
          // Provide defaults for required master-data fields
          // that aren't usually stored in a Sale record
          currentStock: 0,
          isHotkey: false,
          billMachineNumber: 0,
        ),
        mrp: item.stickerPrice,
        quantity: item.qty,
        discountPercent: item.discountPercent,
        // Defaulting to finalPrice as it's the most common restored state
        discountType: item.discountType,
      );
    }).toList();

    cart = PosCart(items: restoredItems);

    // 3. Handle Customer (Assuming your Sale model has customerName/phone)
    // If your Sale model doesn't have a full Customer object,
    // you might need to reconstruct it or fetch it.
    nameController.text = sale.customerName;
    phoneController.text = sale.customerPhone;

    notifyListeners();
  }
}
