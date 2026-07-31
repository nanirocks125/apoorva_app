import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/services/sale_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late SaleService saleService;
  const String orgId = 'apoorva_mangalagiri';

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    saleService = SaleService(db: fakeDb);
  });

  group('SaleService - Atomic Operations', () {
    test('confirmSale should save sale and delete draft atomically', () async {
      // 1. Setup: Create a draft to be cleaned up
      const String draftId = 'draft_99';
      await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('drafts')
          .doc(draftId)
          .set({'customerName': 'Suresh'});

      final sale = Sale(
        id: '', // Will be assigned by Firestore
        customerName: 'Suresh',
        customerPhone: '8121971462',
        netPayable: 5000.0,
        timestamp: DateTime.now(),
        items: [],
        staffId: '',
        subtotal: 0,
        overallDiscountPercent: 10,
        overallDiscountAmount: 100,
        roundOff: 0,
        payments: {},
        source: '',
        status: '',
      );

      // 2. Execute
      final newSaleId = await saleService.confirmSaleWithAtomicCleanup(
        orgId,
        sale,
        draftId,
      );

      // 3. Verify Sale exists
      final saleDoc = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('sales')
          .doc(newSaleId)
          .get();
      expect(saleDoc.exists, isTrue);
      expect(saleDoc.get('customerName'), 'Suresh');

      // 4. Verify Draft is deleted
      final draftDoc = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('drafts')
          .doc(draftId)
          .get();
      expect(draftDoc.exists, isFalse);
    });
  });

  group('SaleService - Queries & Updates', () {
    test('markSaleAsSent should update whatsapp status', () async {
      const String saleId = 'sale_123';
      await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('sales')
          .doc(saleId)
          .set({'whatsappStatus': 'pending'});

      await saleService.markSaleAsSent(orgId: orgId, saleId: saleId);

      final updatedDoc = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('sales')
          .doc(saleId)
          .get();

      expect(updatedDoc.get('whatsappStatus'), 'sent');
    });

    test('getSalesByDate should filter and sort correctly', () async {
      final salesColl = fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('sales');

      // Today's Sale
      await salesColl.add({
        'id': 'sale_today',
        'customerName':
            'Today User', // ✅ Ensure this matches your @JsonKey (snake_case)
        'customerPhone': '8121971462',
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'items': [], // ✅ Must not be null
        'netPayable': 5000.0, // ✅ Model needs these numbers
        'subtotal': 5000.0,
        'overallDiscountPercent': 0,
        'overallDiscountAmount': 0,
        'staffId': 'staff_01',
        'roundOff': 0,
        'payments': <String, dynamic>{},
        'source': 'Walk-in',
        'status': 'Completed',
        'whatsappStatus': 'unsent',
      });

      // Yesterday's Sale
      await salesColl.add({
        'id': 'sale_yesterday',
        'customerName': 'Yesterday User',
        'customerPhone': '8121971462',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        'items': [],
        'netPayable': 3000.0,
        'subtotal': 3000.0,
        'overallDiscountPercent': 0,
        'overallDiscountAmount': 0,
        'staffId': 'staff_01',
        'roundOff': 0,
        'payments': <String, dynamic>{},
        'source': 'Walk-in',
        'status': 'Completed',
        'whatsappStatus': 'unsent',
      });

      final stream = saleService.getSalesByDate(orgId, DateTime.now());
      final results = await stream.first;

      // Should only contain 1 sale (from today)
      expect(results.length, 1);
      expect(results.first.customerName, 'Today User');
    });

    test(
      'getCustomerSales should filter by phone number (snake_case check)',
      () async {
        final salesColl = fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('sales');
        const String targetPhone = '9999999999';

        await salesColl.add({
          'id': 'sale_1',
          'customerName': 'Suresh', // ✅ Added (Required String)
          'customerPhone': targetPhone, // ✅ Changed to snake_case
          'timestamp': Timestamp.now(),
          'items': [], // ✅ Required List
          'netPayable': 5000.0, // ✅ Required num
          'overallDiscountPercent': 0,
          'overallDiscountAmount': 0,
          'subtotal': 5000.0,
          'payments': <String, dynamic>{}, // ✅ Required Typed Map
          'staffId': 'staff_01',
          'source': 'Walk-in',
          'status': 'Completed',
          'whatsappStatus': 'unsent',
          'roundOff': 0, // ✅ Added (Required num)
        });
        await salesColl.add({
          'id': 'sale_2',
          'customerName': 'Ramesh',
          'customerPhone': '0000000000', // ✅ Changed to snake_case
          'timestamp': Timestamp.now(),
          'items': [],
          'netPayable': 1000.0,
          'overallDiscountPercent': 0,
          'overallDiscountAmount': 0,
          'subtotal': 1000.0,
          'payments': <String, dynamic>{},
          'staffId': 'staff_01',
          'source': 'Walk-in',
          'status': 'Completed',
          'whatsappStatus': 'unsent',
          'roundOff': 0, // ✅ Added (Required num)
        });
        final results = await saleService
            .getCustomerSales(orgId, targetPhone)
            .first;

        expect(results.length, 1);
        expect(results.first.customerPhone, targetPhone);
      },
    );
  });

  group('SaleService - Daily Summaries', () {
    test(
      'getDailySummaries should group multiple sales on the same day',
      () async {
        final salesColl = fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('sales');
        final today = DateTime.now();

        // Add 3 sales today
        for (var i = 1; i <= 3; i++) {
          await salesColl.add({
            'id': 's$i',
            'customerName': 'User $i',
            'customerPhone': '1234567890',
            'timestamp': Timestamp.fromDate(today),
            'items': [],
            'netPayable': 1000.0 * i, // 1000, 2000, 3000
            'subtotal': 1000.0 * i,
            'overallDiscountPercent': 0,
            'overallDiscountAmount': 0,
            'staffId': 'staff_01',
            'roundOff': 0,
            'payments': <String, dynamic>{},
            'source': 'Walk-in',
            'status': 'Completed',
            'whatsappStatus': 'unsent',
          });
        }

        final stream = saleService.getDailySummaries(orgId);
        final results = await stream.first;

        // Verify aggregation
        expect(results.length, 1); // Only 1 day represented
        expect(results.first.saleCount, 3); // 3 sales counted
        expect(results.first.totalAmount, 6000.0); // 1000 + 2000 + 3000
      },
    );

    test(
      'getDailySummaries should handle date range filtering correctly',
      () async {
        final salesColl = fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('sales');

        final day1 = DateTime(2026, 4, 1);
        final day2 = DateTime(2026, 4, 5);
        final day3 = DateTime(2026, 4, 10);

        final List<DateTime> dates = [day1, day2, day3];

        for (var date in dates) {
          await salesColl.add({
            'id': '',
            'customerName': 'Test',
            'customerPhone': '000',
            'timestamp': Timestamp.fromDate(date),
            'items': [],
            'netPayable': 500.0,
            'subtotal': 500.0,
            'overallDiscountPercent': 0,
            'overallDiscountAmount': 0,
            'staffId': 'staff_01',
            'roundOff': 0,
            'payments': <String, dynamic>{},
            'source': 'Walk-in',
            'status': 'Completed',
          });
        }

        // Filter for only April 4th to April 6th (Should only catch April 5th)
        final stream = saleService.getDailySummaries(
          orgId,
          startDate: DateTime(2026, 4, 4),
          endDate: DateTime(2026, 4, 6),
        );

        final results = await stream.first;

        expect(results.length, 1);
        expect(results.first.date.day, 5);
      },
    );

    test(
      'getDailySummaries should return empty list when no sales exist',
      () async {
        final stream = saleService.getDailySummaries(orgId);
        final results = await stream.first;

        expect(results, isEmpty);
      },
    );

    test(
      'getDailySummaries should sort by date descending (newest first)',
      () async {
        final salesColl = fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('sales');

        // Add a sale for yesterday and today
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));

        await salesColl.add({
          'id': '1',
          'timestamp': Timestamp.fromDate(yesterday),
          'netPayable': 100.0,
          'customerName': 'A',
          'items': [],
          'subtotal': 100.0,
          'overallDiscountPercent': 0,
          'overallDiscountAmount': 0,
          'staffId': 'S',
          'roundOff': 0,
          'payments': <String, dynamic>{},
          'source': 'W',
          'status': 'C',
          'customerPhone': '1',
        });
        await salesColl.add({
          'id': '2',
          'timestamp': Timestamp.fromDate(today),
          'netPayable': 200.0,
          'customerName': 'B',
          'items': [],
          'subtotal': 200.0,
          'overallDiscountPercent': 0,
          'overallDiscountAmount': 0,
          'staffId': 'S',
          'roundOff': 0,
          'payments': <String, dynamic>{},
          'source': 'W',
          'status': 'C',
          'customerPhone': '2',
        });

        final stream = saleService.getDailySummaries(orgId);
        final results = await stream.first;

        expect(results.length, 2);
        // Newest (Today) should be index 0
        expect(results[0].date.day, today.day);
        expect(results[1].date.day, yesterday.day);
      },
    );
  });
}
