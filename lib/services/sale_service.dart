import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/modules/daily-summary-report/daily_summary_report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SaleService {
  final FirebaseFirestore _db;

  SaleService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<String> confirmSaleWithAtomicCleanup(
    String orgId,
    Sale sale,
    String? activeDraftId,
  ) async {
    final batch = _db.batch();

    // 1. Reference the sale using the ID provided in the object
    // (In Edit mode, this is the existing ID; in New mode, it's the generated one)
    final saleRef = _db
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        .doc(sale.id); // <--- Use sale.id, NOT .doc()

    // 2. Fetch the OLD sale data to calculate the difference (Delta)
    final oldSaleSnap = await saleRef.get();
    bool isEdit = oldSaleSnap.exists;

    double amountDelta = sale.netPayable;
    int salesCountDelta = 1;

    if (isEdit) {
      // If editing, we only add/subtract the difference
      final oldData = oldSaleSnap.data() as Map<String, dynamic>;
      double oldNetPayable = (oldData['netPayable'] ?? 0.0).toDouble();

      amountDelta = sale.netPayable - oldNetPayable;
      salesCountDelta = 0; // Don't increment the sale count for an edit
    }

    // 3. Set/Update the Sale document
    batch.set(saleRef, sale.toJson());

    // 4. Update Customer Statistics with the Delta
    if (sale.customerPhone.isNotEmpty) {
      final customerRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('customers')
          .doc(sale.customerPhone);

      final customerSnap = await customerRef.get();

      if (!customerSnap.exists) {
        batch.set(customerRef, {
          'name': sale.customerName,
          'phone': sale.customerPhone,
          'totalSales': 1,
          'totalAmountSpent': sale.netPayable,
          'lastPurchaseDate': sale.timestamp, // Use sale timestamp
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.update(customerRef, {
          'name': sale.customerName, // Update name in case it changed
          'totalSales': FieldValue.increment(salesCountDelta),
          'totalAmountSpent': FieldValue.increment(amountDelta),
          'lastPurchaseDate': sale.timestamp,
        });
      }
    }

    // 5. Cleanup Draft if necessary
    if (activeDraftId != null && activeDraftId.isNotEmpty) {
      final draftRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('drafts')
          .doc(activeDraftId);
      batch.delete(draftRef);
    }

    await batch.commit();
    return sale.id;
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

      await saleRef.update({'whatsappStatus': 'sent'});
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
        .map((snapshot) {
          // DEBUG: See how many docs came back

          return snapshot.docs.map((doc) {
            final data = doc.data();

            // 🚨 THE SCANNER: This prints every field in this specific document
            data.forEach((key, value) {
              if (value == null) {
              } else {
                // Optional: print everything to be 100% sure
                // print('   Field: $key | Value: $value');
              }
            });

            try {
              return Sale.fromFirestore(doc);
            } catch (e) {
              // If you want the report to load even with bad data,
              // you could return a "Dummy Sale" here instead of rethrowing.
              rethrow;
            }
          }).toList();
        });
  }

  // SaleService క్లాస్ లోపల:
  Stream<List<Sale>> getCustomerSales(String orgId, String phone) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        // DB లో snake_case (customer_phone) వాడుతుంటే ఇక్కడ మార్చండి
        .where('customerPhone', isEqualTo: phone)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Sale>> getTotalSales(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<DailySummary>> getDailySummaries(
    String orgId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('organizations')
        .doc(orgId)
        .collection('sales');

    if (startDate != null && endDate != null) {
      // Note: To include the full "To Date", set it to the end of the day
      query = query
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where(
            'timestamp',
            isLessThanOrEqualTo: endDate.add(const Duration(days: 1)),
          );
    }
    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList(),
        )
        .map((snapshot) => _getDailySummaries(snapshot));
  }

  // Logic to convert List<Sale> to List<DailySummary>
  List<DailySummary> _getDailySummaries(List<Sale> sales) {
    Map<String, List<Sale>> grouped = {};

    for (var sale in sales) {
      // Normalize date to remove time (YYYY-MM-DD)
      String dateKey =
          "${sale.timestamp.year}-${sale.timestamp.month}-${sale.timestamp.day}";
      if (grouped[dateKey] == null) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(sale);
    }

    return grouped.entries.map((entry) {
      double total = entry.value.fold(0, (sum, item) => sum + item.netPayable);
      return DailySummary(
        date: entry.value.first.timestamp,
        totalAmount: total,
        saleCount: entry.value.length,
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }
}
