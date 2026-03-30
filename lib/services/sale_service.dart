import 'package:apoorva_app/model/sale.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';

class SaleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> confirmSaleWithAtomicCleanup(
    String orgId,
    Sale sale,
    String? activeDraftId, // Optional draft ID
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Create a reference for the new sale
    final saleRef = FirebaseFirestore.instance
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        .doc();

    // 2. Add Sale to batch
    batch.set(saleRef, sale.toJson());

    // 3. If it was a resumed draft, add deletion to the same batch
    if (activeDraftId != null && activeDraftId.isNotEmpty) {
      final draftRef = FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .collection('drafts')
          .doc(activeDraftId);
      batch.delete(draftRef);
    }

    // 4. Commit the batch atomically
    await batch.commit();

    return saleRef.id;
  }
}
