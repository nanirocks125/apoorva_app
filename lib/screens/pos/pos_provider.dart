import 'package:flutter/material.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';
import 'package:apoorva_app/model/cart/draft_cart.dart';
import 'package:apoorva_app/services/draft_cart_service.dart';

class PosProvider extends ChangeNotifier {
  final String orgId;
  final PosCart cart = PosCart();
  String? activeDraftId;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  PosProvider({required this.orgId});

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

  void updateItem(CartItem updatedItem) {
    // Guard index-based cart mutations to avoid RangeError

    final index = cart.items.indexWhere(
      (item) => item.category.id == updatedItem.category.id,
    );
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
}
