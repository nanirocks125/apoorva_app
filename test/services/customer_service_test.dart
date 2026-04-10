import 'package:apoorva_app/services/customer_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:apoorva_app/model/customer/customer.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late CustomerService customerService;
  const String orgId = 'apoorva_mangalagiri';

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    customerService = CustomerService(db: fakeDb);
  });

  group('CustomerService Tests', () {
    test(
      'getCustomers should return a real-time stream of customers',
      () async {
        // 1. Setup: Add a mock customer to the fake database
        await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('customers')
            .add({
              'name': 'Suresh',
              'phone': '9876543210',
              'created_at': DateTime.now(),
              'visitCount': 1,
            });

        // 2. Execute: Listen to the stream
        final stream = customerService.getCustomers(orgId);
        final firstResult = await stream.first;

        // 3. Verify
        expect(firstResult.length, 1);
        expect(firstResult.first.name, 'Suresh');
      },
    );

    test('saveCustomer should CREATE a new record when ID is null', () async {
      final newCustomer = Customer(
        name: 'Lavanya',
        phone: '8888888888',
        createdAt: DateTime.now(),
        lastPurchaseDate: DateTime.now(),
      );

      await customerService.saveCustomer(orgId, newCustomer);

      final snapshot = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('customers')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.get('name'), 'Lavanya');
    });

    test(
      'saveCustomer should UPDATE an existing record when ID is provided',
      () async {
        final String testPhone = '1111111111';
        // 1. Setup: Create an existing customer using the PHONE NUMBER as the ID
        final docRef = fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('customers')
            .doc(testPhone); // ✅ FIX 1: Use .doc(phone) instead of .add()

        await docRef.set({
          'name': 'Old Name',
          'phone': testPhone,
          // Since it's a raw map, pass actual Timestamp or String depending on your FakeFirestore setup
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'totalSales': 0,
        });

        // 2. Create updated model
        final updatedCustomer = Customer(
          name: 'New Name',
          phone: testPhone,
          createdAt: DateTime.now(),
          lastPurchaseDate: DateTime.now(),
          totalSales: 5,
        );

        // 3. Execute
        await customerService.saveCustomer(orgId, updatedCustomer);

        // 4. Verify
        final updatedDoc = await docRef
            .get(); // Fetch the specific phone document
        expect(updatedDoc.get('name'), 'New Name');
        expect(
          updatedDoc.get('totalSales'),
          5,
        ); // ✅ FIX 2: Expect 5, since that's what we passed in
      },
    );
  });
}
