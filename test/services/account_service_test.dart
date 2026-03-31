import 'package:apoorva_app/model/internal_transfer.dart';
import 'package:apoorva_app/services/account_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late AccountService accountService;

  const String orgId = 'apoorva_mangalagiri';
  const String fromId = 'cash_drawer';
  const String toId = 'hdfc_bank';

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    // Note: You'll need to modify your AccountService to accept a Firestore instance
    // for dependency injection (e.g., AccountService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance)
    accountService = AccountService(db: fakeDb);
  });

  group('AccountService - Internal Transfer Tests', () {
    test(
      'Successful transfer updates both balances and creates a record',
      () async {
        // 1. Setup: Seed the fake database
        await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('accounts')
            .doc(fromId)
            .set({'name': 'Cash Drawer', 'current_balance': 5000.0});
        await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('accounts')
            .doc(toId)
            .set({'name': 'HDFC Bank', 'current_balance': 1000.0});

        final transfer = InternalTransfer(
          id: '', // Will be replaced by service
          fromAccountId: fromId,
          toAccountId: toId,
          amount: 2000.0,
          transferType: 'Deposit',
          timestamp: DateTime.now(),
        );

        // 2. Execute
        await accountService.executeInternalTransfer(orgId, transfer);

        // 3. Verify Balances
        final fromSnap = await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('accounts')
            .doc(fromId)
            .get();
        final toSnap = await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('accounts')
            .doc(toId)
            .get();

        expect(fromSnap.get('current_balance'), 3000.0); // 5000 - 2000
        expect(toSnap.get('current_balance'), 3000.0); // 1000 + 2000

        // 4. Verify Transfer Record
        final transfersSnap = await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('transfers')
            .get();
        expect(transfersSnap.docs.length, 1);
        expect(transfersSnap.docs.first.get('amount'), 2000.0);
      },
    );

    test(
      'Should throw exception and not update if funds are insufficient',
      () async {
        // Setup with low balance
        await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('accounts')
            .doc(fromId)
            .set({'current_balance': 100.0});
        await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('accounts')
            .doc(toId)
            .set({'current_balance': 500.0});

        final transfer = InternalTransfer(
          id: '',
          fromAccountId: fromId,
          toAccountId: toId,
          amount: 1000.0, // More than available
          transferType: 'Deposit',
          timestamp: DateTime.now(),
        );

        // Execute & Verify Exception
        expect(
          () => accountService.executeInternalTransfer(orgId, transfer),
          throwsA(isA<Exception>()),
        );

        // Verify balances remained unchanged (Transaction rollback simulation)
        final fromSnap = await fakeDb
            .collection('organizations')
            .doc(orgId)
            .collection('accounts')
            .doc(fromId)
            .get();
        expect(fromSnap.get('current_balance'), 100.0);
      },
    );
  });
}
