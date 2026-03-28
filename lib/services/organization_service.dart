import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apoorva_app/model/organization.dart';

class OrganizationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Real-time stream: Now returns a clean list of Organization objects
  Stream<List<Organization>> getOrganizations() {
    return _db.collection('organizations').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // 1. Convert Map to Model
        final org = Organization.fromJson(doc.data());
        // 2. Inject the mandatory ID from metadata
        org.id = doc.id;
        return org;
      }).toList();
    });
  }

  // Create: Simply pass the seeded model. No transactions needed for the array!
  Future<void> createOrganization(Organization newOrg) async {
    // 1. Manually generate a document reference to get the ID immediately
    final docRef = _db.collection('organizations').doc();

    // 2. Assign that ID to your model object
    newOrg.id = docRef.id;
    await docRef.set(newOrg.toJson());
  }

  // Update: Uses the automated JSON logic
  Future<void> updateOrganization(Organization org) async {
    await _db.collection('organizations').doc(org.id).update(org.toJson());
  }

  // Toggle Status: Simple field update
  Future<void> toggleStatus(String orgId, String currentStatus) async {
    String newStatus = currentStatus == 'Active' ? 'Inactive' : 'Active';
    await _db.collection('organizations').doc(orgId).update({
      'status': newStatus,
    });
  }

  // Delete: Wipes the document and its sub-collections
  Future<void> deleteOrganization(String orgId) async {
    final orgRef = _db.collection('organizations').doc(orgId);

    // Sub-collections that might still have legacy data
    List<String> subCollections = [
      'users',
      'categories',
      'sales',
      'expenses',
      'vendor_purchases',
      'customers',
      'audit_logs',
    ];

    for (var collectionName in subCollections) {
      var snapshots = await orgRef.collection(collectionName).get();
      var batch = _db.batch();
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    await orgRef.delete();
  }
}
