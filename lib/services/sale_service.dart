import 'package:apoorva_app/model/customer/customer.dart';
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
    // ❌ WRONG: final batch = FirebaseFirestore.instance.batch();
    // ✅ RIGHT: Use the injected database
    final batch = _db.batch();

    // ❌ WRONG: final saleRef = FirebaseFirestore.instance.collection(...)
    // ✅ RIGHT: Use the injected database
    final saleRef = _db
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        .doc();

    batch.set(saleRef, sale.toJson());

    // 2. Prepare the Customer Reference (The Missing Part!)
    // We use the phone number as the document ID to prevent duplicates
    if (sale.customerPhone.isNotEmpty) {
      final customerRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('customers')
          .doc(
            sale.customerPhone,
          ); // Using phone as ID is great for quick lookups

      // 1. CHECK IF CUSTOMER EXISTS FIRST
      final customerSnap = await customerRef.get();

      // 2. Base data that gets updated EVERY time
      Map<String, dynamic> customerData = {
        'name': sale.customerName,
        'phone': sale.customerPhone,
        'lastPurchaseDate': FieldValue.serverTimestamp(),
      };

      if (!customerSnap.exists) {
        // 🟢 SCENARIO A: BRAND NEW CUSTOMER
        // We set the createdAt timestamp because this is their first visit!
        customerData['createdAt'] = FieldValue.serverTimestamp();

        // Hardcode the first values instead of using increment
        customerData['totalSales'] = 1;
        customerData['totalAmountSpent'] = sale.netPayable;

        // Create the document (No merge needed)
        batch.set(customerRef, customerData);
      } else {
        // 🔵 SCENARIO B: EXISTING CUSTOMER
        // We do NOT include 'createdAt' here, so their original date is safe.
        customerData['totalSales'] = FieldValue.increment(1);
        customerData['totalAmountSpent'] = FieldValue.increment(
          sale.netPayable,
        );

        // Update the document safely
        batch.set(customerRef, customerData, SetOptions(merge: true));
      }
    }

    if (activeDraftId != null && activeDraftId.isNotEmpty) {
      // ✅ Ensure the draft reference also uses _db
      final draftRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('drafts')
          .doc(activeDraftId);
      batch.delete(draftRef);
    }

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
