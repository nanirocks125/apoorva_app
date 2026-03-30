import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/model/sale_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apoorva_app/enum/payment_mode.dart';

void main() {
  final testDate = DateTime(2026, 3, 30, 23, 50, 0);
  final mockTimestamp = Timestamp.fromDate(testDate);

  // Setup mock items for the sale
  final mockSaleItems = [
    SaleItem(
      categoryId: 'gold_01',
      categoryName: 'Bangles',
      qty: 1,
      stickerPrice: 1000.0,
      finalPrice: 900.0,
    ),
  ];

  group('Sale Model Tests', () {
    test('Constructor should initialize all financial fields correctly', () {
      final sale = Sale(
        id: 'sale_123',
        staffId: 'staff_manikanta',
        customerPhone: '8121971462',
        customerName: 'Manikanta',
        items: mockSaleItems,
        subtotal: 1000.0,
        overallDiscountPercent: 10.0,
        overallDiscountAmount: 100.0,
        roundOff: 0.0,
        netPayable: 900.0,
        payments: {PaymentMode.cash: 900.0},
        timestamp: testDate,
        source: 'Walk-in',
        status: 'Completed',
      );

      expect(sale.netPayable, 900.0);
      expect(sale.payments[PaymentMode.cash], 900.0);
      expect(sale.whatsappStatus, 'unsent'); // Check default value
    });

    test('copyWithId should create a deep copy with a new ID', () {
      final sale = Sale(
        id: 'temp_id',
        staffId: 'staff_1',
        customerPhone: '9999999999',
        customerName: 'Lavanya',
        items: mockSaleItems,
        subtotal: 100.0,
        overallDiscountPercent: 0,
        overallDiscountAmount: 0,
        roundOff: 0,
        netPayable: 100.0,
        payments: {PaymentMode.upi: 100.0},
        timestamp: testDate,
        source: 'Instagram',
        status: 'Completed',
      );

      final newSale = sale.copyWithId('confirmed_id_456');

      expect(newSale.id, 'confirmed_id_456');
      expect(newSale.customerName, 'Lavanya');
      expect(identical(sale, newSale), isFalse);
    });

    group('JSON Serialization (toJson)', () {
      test('should correctly serialize nested items and payment map', () {
        final sale = Sale(
          id: 'sale_789',
          staffId: 's1',
          customerPhone: '7777777777',
          customerName: 'Suresh',
          items: mockSaleItems,
          subtotal: 1000.0,
          overallDiscountPercent: 0,
          overallDiscountAmount: 0,
          roundOff: 0,
          netPayable: 1000.0,
          payments: {PaymentMode.cash: 500.0, PaymentMode.upi: 500.0},
          timestamp: testDate,
          source: 'Walk-in',
          status: 'Completed',
        );

        final json = sale.toJson();

        // 1. Check nested list serialization (explicitToJson: true)
        expect(json['items'][0]['cat_id'], 'gold_01');

        // 2. Check Enum Map serialization
        // Note: json_serializable converts PaymentMode.cash to 'cash'
        expect(json['payments']['cash'], 500.0);
        expect(json['payments']['upi'], 500.0);

        // 3. Check Timestamp conversion
        expect(json['timestamp'], isA<Timestamp>());
      });
    });

    group('JSON Deserialization (fromJson)', () {
      test('should handle Firestore data correctly', () {
        final json = {
          'id': 'firestore_doc_id',
          'staffId': 'staff_1',
          'customerPhone': '8888888888',
          'customerName': 'Ramesh',
          'items': [
            {
              'cat_id': 'bangle_01',
              'categoryName': 'Bangles',
              'qty': 1,
              'stickerPrice': 500.0,
              'finalPrice': 450.0,
            },
          ],
          'subtotal': 500.0,
          'overallDiscountPercent': 10.0,
          'overallDiscountAmount': 50.0,
          'roundOff': 0.0,
          'netPayable': 450.0,
          'payments': {'cash': 450.0},
          'timestamp': mockTimestamp,
          'source': 'WhatsApp',
          'status': 'Completed',
          'whatsappStatus': 'sent',
        };

        final sale = Sale.fromJson(json);

        expect(sale.customerName, 'Ramesh');
        expect(sale.netPayable, 450.0);
        expect(sale.payments[PaymentMode.cash], 450.0);
        expect(sale.items.first.categoryName, 'Bangles');
        expect(sale.timestamp.year, 2026);
      });
    });
  });
}
