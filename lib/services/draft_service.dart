// Location: lib/services/draft_service.dart (లేదా SaleService లోనే కలపండి)
import 'package:apoorva_app/model/cart/cart_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DraftService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveDraft({
    required String orgId,
    required String customerName,
    required String customerPhone,
    required List<CartItem> items,
  }) async {
    final draftData = {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items
          .map(
            (i) => {
              'categoryId': i.category.id,
              'categoryName': i.category.name,
              'stickerPrice': i.stickerPrice,
              'discountPercent': i.discountPercent,
            },
          )
          .toList(),
      'timestamp': FieldValue.serverTimestamp(),
      'total': items.fold(0.0, (sum, i) => sum + i.finalPrice),
    };

    await _db
        .collection('organizations')
        .doc(orgId)
        .collection('drafts')
        .add(draftData);
  }

  // డ్రాఫ్ట్ ని లోడ్ చేసిన తర్వాత డిలీట్ చేయడానికి
  Future<void> deleteDraft(String orgId, String draftId) async {
    await _db
        .collection('organizations')
        .doc(orgId)
        .collection('drafts')
        .doc(draftId)
        .delete();
  }
}
