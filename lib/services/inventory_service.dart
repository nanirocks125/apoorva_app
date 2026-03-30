import 'package:apoorva_app/model/category/category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Real-time stream for the POS and Inventory screens
  Stream<List<Category>> getCategories(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('inventory')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList(),
        );
  }

  // Atomic Save: Handles both Create and Update
  Future<void> saveCategory(String orgId, Category category) async {
    final collection = _db
        .collection('organizations')
        .doc(orgId)
        .collection('inventory');

    if (category.id.isEmpty) {
      // 1. CREATE: ID is empty, let Firestore generate a unique one
      await collection.add(category.toJson());
    } else {
      // 2. UPDATE: Target the existing document ID
      // Using set with merge: true is safer than update()
      // as it creates the doc if it somehow went missing.
      await collection
          .doc(category.id)
          .set(category.toJson(), SetOptions(merge: true));
    }
  }

  // 3. DELETE: Essential for maintaining a clean inventory
  Future<void> deleteCategory(String orgId, String categoryId) async {
    await _db
        .collection('organizations')
        .doc(orgId)
        .collection('inventory')
        .doc(categoryId)
        .delete();
  }
}
