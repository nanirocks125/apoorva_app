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

  Future<void> markSaleAsSent({
    required String orgId,
    required String saleId,
  }) async {
    try {
      final saleRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('sales')
          .doc(saleId);

      await saleRef.update({
        'whatsapp_status': 'sent',
        'last_shared_at': FieldValue.serverTimestamp(), // Audit trail కోసం
      });
    } catch (e) {
      print("Error updating sale status: $e");
      rethrow; // UI లో ఎర్రర్ చూపించడానికి rethrow చేస్తున్నాం
    }
  }

  // SaleService క్లాస్ లోపల:
  Stream<List<Sale>> getSalesByDate(String orgId, DateTime date) {
    // రోజు ప్రారంభం మరియు ముగింపు సమయాలు
    DateTime start = DateTime(date.year, date.month, date.day, 0, 0, 0);
    DateTime end = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList(),
        );
  }

  // SaleService క్లాస్ లోపల:
  Stream<List<Sale>> getCustomerSales(String orgId, String phone) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        // DB లో snake_case (customer_phone) వాడుతుంటే ఇక్కడ మార్చండి
        .where('customer_phone', isEqualTo: phone)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList(),
        );
  }
}
