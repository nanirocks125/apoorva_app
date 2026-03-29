import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apoorva_app/model/organization/organization.dart';

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

  Future<Organization?> getOrganizationById(String orgId) async {
    print(
      'getting organization for ID: $orgId',
    ); // Debug log to check the input
    final doc = await _db
        .collection('organizations')
        .doc(orgId.trim())
        .get(); // trim() వాడండి
    if (doc.exists) {
      print(
        'doc exists for orgId $orgId: ${doc.data()}',
      ); // Check if data is actually there
      try {
        print(
          'doc.data() for orgId $orgId: ${doc.data()}',
        ); // ఇక్కడ డేటా వస్తుందా అని చెక్ చేయండి
        return Organization.fromJson(doc.data()!);
      } catch (e) {
        print("Parsing Error: $e"); // ఇక్కడ అసలు ఎర్రర్ ఏంటో తెలుస్తుంది
        return null;
      }
    } else {
      print(
        'document does not exist for orgId $orgId',
      ); // డాక్యుమెంట్ లేనిది కూడా చెక్ చేయండి
    }
    return null;
  }

  Future<List<Organization>> getMultipleOrgsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Firestore 'whereIn' is perfect for this, up to 10-30 IDs
    final query = await _db
        .collection('organizations')
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    return query.docs.map((doc) => Organization.fromJson(doc.data())).toList();
  }

  Stream<List<Map<String, dynamic>>> getLiveCategories(String orgId) {
    return FirebaseFirestore.instance
        .collection('organizations')
        .doc(orgId)
        .collection('inventory') // మీ PRD ప్రకారం inventory సబ్-కలెక్షన్
        .orderBy('is_hotkey', descending: true) // హాట్-కీలు పైన ఉంటాయి
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }
}
