import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Real-time stream of all organizations for your master view
  Stream<List<Map<String, dynamic>>> getOrganizations() {
    return _db
        .collection('organizations')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // Create & Seed: Ensures Org and Accounts are created together [cite: 95, 174, 182]
  Future<void> createOrganization({
    required String name,
    required double initialCash,
    required double initialBank,
  }) async {
    DocumentReference orgRef = _db.collection('organizations').doc();

    return _db.runTransaction((transaction) async {
      // 1. Root Document [cite: 95-110]
      transaction.set(orgRef, {
        'org_name': name,
        'status': 'Active',
        'created_at': FieldValue.serverTimestamp(),
        'config': {
          'system': {'min_version': '1.0.0'},
          'ui_theme': {'current_theme': 'Default', 'accent_color': '#FF5733'},
        },
      });

      // 2. Seed Initial Accounts for Net Cash tracking [cite: 34, 182]
      transaction.set(orgRef.collection('accounts').doc('shop_cash'), {
        'name': 'Shop Cash Drawer',
        'account_type': 'Cash',
        'current_balance': initialCash,
        'last_updated': FieldValue.serverTimestamp(),
      });
      transaction.set(orgRef.collection('accounts').doc('sbi_bank'), {
        'name': 'SBI Bank Account',
        'account_type': 'Bank',
        'current_balance': initialBank,
        'is_default_upi': true,
        'last_updated': FieldValue.serverTimestamp(),
      });
    });
  }

  // Update Organization Details [cite: 98]
  Future<void> updateOrganization(String orgId, String name) async {
    await _db.collection('organizations').doc(orgId).update({'org_name': name});
  }

  // Toggle Status: Revoke access instantly [cite: 120]
  Future<void> toggleStatus(String orgId, String currentStatus) async {
    String newStatus = currentStatus == 'Active' ? 'Inactive' : 'Active';
    await _db.collection('organizations').doc(orgId).update({
      'status': newStatus,
    });
  }

  // Delete Organization (Master Admin Power) [cite: 65]
  Future<void> deleteOrganization(String orgId) async {
    await _db.collection('organizations').doc(orgId).delete();
  }
}
