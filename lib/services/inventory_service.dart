import 'package:apoorva_app/model/category/category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveCategory(String orgId, Category category) async {
    final collection = _db
        .collection('organizations')
        .doc(orgId)
        .collection('inventory');

    if (category.id.isEmpty) {
      // 1. Pre-generate the Doc ID
      final newDocRef = collection.doc();

      // 2. Inject that ID into the model before saving
      final categoryWithId = category.copyWithId(newDocRef.id);

      // 3. Save the JSON (which now contains the matching ID)
      await newDocRef.set(categoryWithId.toJson());
    } else {
      // UPDATE: Simply target the existing ID
      await collection
          .doc(category.id)
          .set(category.toJson(), SetOptions(merge: true));
    }
  }

  Stream<List<Category>> getCategories(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('inventory')
        .orderBy('name')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Category.fromFirestore(doc)).toList(),
        );
  }
}
