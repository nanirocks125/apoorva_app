import 'package:flutter/material.dart';
import '../../model/cart/cart_item.dart';
import '../../model/cart/pos_cart.dart';
import '../../model/cart/draft_cart.dart';
import '../../services/draft_cart_service.dart';

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
    cart.items.removeAt(index);
    notifyListeners();
  }

  void updateItem(int index, CartItem newItem) {
    cart.items[index] = newItem;
    notifyListeners();
  }

  Future<void> holdCurrentBill() async {
    if (cart.items.isEmpty) return;

    await DraftCartService().saveDraft(
      orgId,
      DraftCart(
        id: '',
        customerName: nameController.text,
        customerPhone: phoneController.text,
        items: List.from(cart.items),
        total: cart.totalPayable,
        createdAt: DateTime.now(),
      ),
    );
    clearCart();
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
