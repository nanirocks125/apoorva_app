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
}
