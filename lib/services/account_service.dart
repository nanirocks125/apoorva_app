import 'package:apoorva_app/model/internal_transfer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountService {
  final FirebaseFirestore _db;

  AccountService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  Future<void> executeInternalTransfer(
    String orgId,
    InternalTransfer transfer,
  ) async {
    final transferRef = _db
        .collection('organizations')
        .doc(orgId)
        .collection('transfers')
        .doc();
    final fromAccRef = _db
        .collection('organizations')
        .doc(orgId)
        .collection('accounts')
        .doc(transfer.fromAccountId);
    final toAccRef = _db
        .collection('organizations')
        .doc(orgId)
        .collection('accounts')
        .doc(transfer.toAccountId);

    await _db.runTransaction((transaction) async {
      // 1. అకౌంట్ బ్యాలెన్స్ లు చెక్ చేయడం
      DocumentSnapshot fromSnap = await transaction.get(fromAccRef);
      double currentFromBalance = fromSnap.get('current_balance') ?? 0.0;

      if (currentFromBalance < transfer.amount) {
        throw Exception("In-sufficient funds in source account!");
      }

      // 2. బ్యాలెన్స్ అప్‌డేట్ చేయడం
      transaction.update(fromAccRef, {
        'current_balance': FieldValue.increment(-transfer.amount),
      });
      transaction.update(toAccRef, {
        'current_balance': FieldValue.increment(transfer.amount),
      });

      // 3. ట్రాన్స్‌ఫర్ రికార్డ్ సేవ్ చేయడం (ID ఇంజెక్ట్ చేసి)
      final finalTransfer = transfer.copyWithId(transferRef.id);
      transaction.set(transferRef, finalTransfer.toJson());
    });
  }
}
