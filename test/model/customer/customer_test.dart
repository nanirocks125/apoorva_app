import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apoorva_app/model/customer/customer.dart';

void main() {
  final testDate = DateTime(2026, 3, 30, 10, 0, 0);

  group('Customer Model Tests', () {
    test('Constructor should initialize fields correctly', () {
      final customer = Customer(
        name: 'Manikanta',
        phone: '8121971462',
        createdAt: testDate,
        lastPurchaseDate: testDate,
        totalSales: 5,
      );

      expect(customer.name, 'Manikanta');
      expect(customer.phone, '8121971462');
      expect(customer.totalSales, 5);
    });

    group('JSON Serialization', () {
      test('toJson should convert fields correctly for Firestore', () {
        final customer = Customer(
          name: 'Suresh',
          phone: '7777777777',
          createdAt: testDate,
          lastPurchaseDate: testDate,
          totalSales: 2,
        );

        final json = customer.toJson();

        expect(json['name'], 'Suresh');
        expect(json['phone'], '7777777777');
        expect(json['visitCount'], 2);
        // Verify custom timestamp converter key
        expect(json['created_at'], isA<Timestamp>());
        // ID should NOT be in JSON based on @JsonKey(includeToJson: false)
        expect(json.containsKey('id'), isFalse);
      });

      test(
        'fromJson should handle Firestore Timestamps and default values',
        () {
          final json = {
            'name': 'Ramesh',
            'phone': '8888888888',
            'created_at': Timestamp.fromDate(testDate),
            // visitCount is missing to test defaultValue
          };

          final customer = Customer.fromJson(json);

          expect(customer.name, 'Ramesh');
          expect(customer.totalSales, 0); // Default value from annotation
          expect(customer.createdAt, testDate);
        },
      );
    });
  });
}
