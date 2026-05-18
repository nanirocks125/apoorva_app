import 'package:apoorva_app/model/customer/customer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerService {
  final FirebaseFirestore _db;

  // Defaults to real Firestore in production, uses Fake in tests
  CustomerService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  // Stream of customers for real-time updates in Mangalagiri
  Stream<List<Customer>> getCustomers(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('customers')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Customer.fromJson(doc.data()))
              .toList(),
        );
  }

  // Future for one-time fetches (e.g., during checkout)
  Future<void> saveCustomer(String orgId, Customer customer) async {
    print("Attempting to save to: organizations/$orgId/customers");
    final ref = _db
        .collection('organizations')
        .doc(orgId)
        .collection('customers');

    try {
      await ref
          .doc(customer.phone)
          .set(customer.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Save failed: $e");
    }
  }

  // ✅ DEACTIVATE CUSTOMER
  Future<void> toggleCustomerStatus(
    String orgId,
    String phone,
    bool isActive,
  ) async {
    try {
      await _db
          .collection('organizations')
          .doc(orgId)
          .collection('customers')
          .doc(phone)
          .update({'isActive': isActive});
    } catch (e) {
      debugPrint("❌ Status update failed: $e");
      rethrow;
    }
  }

  // ✅ DELETE CUSTOMER
  Future<void> deleteCustomer(String orgId, String phone) async {
    try {
      await _db
          .collection('organizations')
          .doc(orgId)
          .collection('customers')
          .doc(phone)
          .delete();
    } catch (e) {
      debugPrint("❌ Delete failed: $e");
      rethrow;
    }
  }

  // 1. VIP Customers (Highest purchase frequency)
  Future<List<Customer>> getTopVIPCustomers(
    String orgId, {
    int limit = 10,
  }) async {
    final snap = await _db
        .collection('organizations')
        .doc(orgId)
        .collection('customers')
        .orderBy('totalSales', descending: true)
        .limit(limit)
        .get();

    return snap.docs.map((doc) => Customer.fromJson(doc.data())).toList();
  }

  // 2. Lapsed Customers (No purchases in the last 6 months)
  // Assumes lastPurchaseDate is saved as a Timestamp (as seen in your SaleService)
  Future<List<Customer>> getLapsedCustomers(String orgId) async {
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));

    final snap = await _db
        .collection('organizations')
        .doc(orgId)
        .collection('customers')
        .where('lastPurchaseDate', isLessThan: Timestamp.fromDate(sixMonthsAgo))
        .orderBy('lastPurchaseDate', descending: false) // Oldest first
        .limit(20)
        .get();

    return snap.docs.map((doc) => Customer.fromJson(doc.data())).toList();
  }

  // 3. Upcoming Events (Birthdays/Anniversaries in the current month)
  // Uses your "MM-DD" string format to query efficiently!
  Future<Map<String, List<Customer>>> getThisMonthsEvents(String orgId) async {
    final currentMonthStr = DateFormat('MM').format(DateTime.now());

    // Query limits to current month e.g., "04-00" to "04-32"
    final startRange = "$currentMonthStr-00";
    final endRange = "$currentMonthStr-32";

    final ref = _db
        .collection('organizations')
        .doc(orgId)
        .collection('customers');

    // Fetch Birthdays
    final bdaySnap = await ref
        .where('birthday', isGreaterThanOrEqualTo: startRange)
        .where('birthday', isLessThan: endRange)
        .get();

    // Fetch Anniversaries
    final annivSnap = await ref
        .where('anniversary', isGreaterThanOrEqualTo: startRange)
        .where('anniversary', isLessThan: endRange)
        .get();

    return {
      'birthdays': bdaySnap.docs
          .map((d) => Customer.fromJson(d.data()))
          .toList(),
      'anniversaries': annivSnap.docs
          .map((d) => Customer.fromJson(d.data()))
          .toList(),
    };
  }

  Future<List<Customer>> getTopSpenders(String orgId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(orgId)
        .collection('customers')
        .orderBy('totalAmountSpent', descending: true)
        .limit(10) // Limit to top 10 spenders
        .get();

    return querySnapshot.docs
        .map((doc) => Customer.fromJson(doc.data()))
        .toList();
  }

  Future<List<Customer>> searchCustomers(String orgId, String query) async {
    if (query.length < 3) return [];

    // Prefix search logic: 'Mani' తో స్టార్ట్ అయ్యే పేర్లన్నీ వస్తాయి
    var snapshot = await _db
        .collection('organizations')
        .doc(orgId)
        .collection('customers')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => Customer.fromJson(doc.data())).toList();
  }
}
