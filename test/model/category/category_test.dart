import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  final testDate = DateTime(2026, 3, 30, 10, 0, 0);

  group('Category Model Tests', () {
    test('should correctly create an instance from constructor', () {
      final category = Category(
        id: '101',
        name: 'Gold Bangles',
        currentStock: 50,
        isHotkey: true,
        billMachineNumber: 1,
        lastSoldDate: testDate,
      );

      expect(category.name, 'Gold Bangles');
      expect(category.billMachineNumber, 1);
      expect(category.isHotkey, isTrue);
    });

    test('copyWithId should return new instance with updated ID', () {
      final category = Category(
        id: 'old_id',
        name: 'Earrings',
        currentStock: 20,
        isHotkey: false,
        billMachineNumber: 2,
      );

      final updatedCategory = category.copyWithId('new_102');

      expect(updatedCategory.id, 'new_102');
      expect(updatedCategory.name, 'Earrings'); // Remains same
      expect(identical(category, updatedCategory), isFalse);
    });

    group('JSON Serialization', () {
      test('toJson should handle nullable lastSoldDate', () {
        final category = Category(
          id: '103',
          name: 'Chains',
          currentStock: 10,
          isHotkey: false,
          billMachineNumber: 1,
          lastSoldDate: null,
        );

        final json = category.toJson();

        expect(json['name'], 'Chains');
        expect(json['lastSoldDate'], isNull);
        expect(json['billMachineNumber'], 1);
      });

      test('fromJson should handle Firestore Timestamp correctly', () {
        final json = {
          'id': '104',
          'name': 'Rings',
          'currentStock': 100,
          'isHotkey': true,
          'billMachineNumber': 3,
          'lastSoldDate': Timestamp.fromDate(
            testDate,
          ), // Simulated Firestore data
        };

        final category = Category.fromJson(json);

        expect(category.name, 'Rings');
        expect(category.lastSoldDate, isA<DateTime>());
        expect(category.lastSoldDate?.year, 2026);
      });
    });
  });
}
