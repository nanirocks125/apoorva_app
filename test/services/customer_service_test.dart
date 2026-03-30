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
        // 1. Setup: Create an existing customer
        final docRef = await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('customers')
            .add({
              'name': 'Old Name',
              'phone': '0000000000',
              'created_at': DateTime.now(),
              'visitCount': 0,
            });

        // 2. Create updated model using the generated ID
        final updatedCustomer = Customer(
          id: docRef.id,
          name: 'New Name',
          phone: '1111111111',
          createdAt: DateTime.now(),
          visitCount: 5,
        );

        // 3. Execute
        await customerService.saveCustomer(orgId, updatedCustomer);

        // 4. Verify
        final updatedDoc = await docRef.get();
        expect(updatedDoc.get('name'), 'New Name');
        expect(updatedDoc.get('visitCount'), 5);
      },
    );
  });
}
