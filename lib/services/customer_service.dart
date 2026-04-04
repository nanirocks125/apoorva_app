import 'package:apoorva_app/model/customer/customer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
          (snapshot) =>
              snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList(),
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
      if (customer.id == null) {
        await ref.add(customer.toJson());
      } else {
        await ref.doc(customer.id).update(customer.toJson());
      }
    } catch (e) {
      debugPrint("❌ Save failed: $e");
    }
  }
}
