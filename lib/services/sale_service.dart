import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:apoorva_app/model/cart/pos_cart.dart';

class SaleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> confirmSaleWithAtomicCleanup({
    required String orgId,
    required String customerName,
    required String customerPhone,
    required List items,
    required double subtotal,
    required double overallDiscountPercent,
    required double overallDiscountAmount,
    required double roundOff,
    required double netPayable,
    required Map<String, double> payments,
    String? activeDraftId, // Optional draft ID
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1. Create a reference for the new sale
    final saleRef = FirebaseFirestore.instance
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        .doc();

    // 2. Add Sale to batch
    batch.set(saleRef, {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items,
      'subtotal': subtotal,
      'overallDiscountPercent': overallDiscountPercent,
      'overallDiscountAmount': overallDiscountAmount,
      'roundOff': roundOff,
      'netPayable': netPayable,
      'payments': payments,
      'timestamp': FieldValue.serverTimestamp(),
      'whatsapp_status': 'unsent', // Initial status
    });

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

  Future<String> confirmSale({
    required String orgId,
    required PosCart cart,
    required String customerName,
    required String customerPhone,
    required double overallDiscountPercent,
    required double overallDiscountAmount,
    required double roundOff,
    required double netPayable,
    required Map<String, double> payments, // Tender Splitting breakdown
  }) async {
    final batch = _db.batch();
    final String saleId = _db
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        .doc()
        .id;
    final saleRef = _db
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        .doc(saleId);

    // 1. Prepare Sale Data including Financial Breakdown [cite: 39]
    final saleData = {
      'id': saleId,
      'customerName': customerName.isEmpty ? 'Walk-in' : customerName,
      'customerPhone': customerPhone,
      'items': cart.items
          .map(
            (item) => {
              'categoryId': item.categoryId,
              'name': item.categoryName,
              'stickerPrice': item.stickerPrice,
              'itemDiscountPercent': item.discountPercent,
              'finalPrice': item.finalPrice,
            },
          )
          .toList(),
      'subtotal': cart.totalPayable,
      'overallDiscountPercent': overallDiscountPercent,
      'overallDiscountAmount': overallDiscountAmount,
      'roundOff': roundOff,
      'netPayable': netPayable,
      'payments': payments, // e.g., {'Cash': 1000, 'UPI': 40}
      'totalCollected': payments.values.fold(0.0, (sum, val) => sum + val),
      'balance':
          netPayable -
          payments.values.fold(
            0.0,
            (sum, val) => sum + val,
          ), // Debt/Credit tracking
      'timestamp': FieldValue.serverTimestamp(),
      'processedBy': FirebaseAuth.instance.currentUser?.uid,
    };

    batch.set(saleRef, saleData);

    // 2. Atomic Inventory Update (Category Level)
    // Since we track categories in bulk (e.g., Bangles), we decrement stock for each item sold [cite: 28]
    for (var item in cart.items) {
      final categoryRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('inventory')
          .doc(item.categoryId);
      batch.update(categoryRef, {
        'current_stock': FieldValue.increment(-1), // Simple integer decrement
        'last_sold_date':
            FieldValue.serverTimestamp(), // Crucial for Dead Stock Analytics [cite: 40]
      });
    }

    // 3. Optional: Upsert Customer Record for Loyalty Tracking [cite: 36, 44]
    if (customerPhone.isNotEmpty) {
      final customerRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('customers')
          .doc(customerPhone);
      batch.set(customerRef, {
        'name': customerName,
        'phone': customerPhone,
        'lastVisit': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    return saleId;
  }
}
