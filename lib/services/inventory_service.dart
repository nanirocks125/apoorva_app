import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/model/category_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryService {
  final FirebaseFirestore _db;

  InventoryService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  Future<void> saveCategory(String orgId, Category category) async {
    final collection = _db
        .collection('organizations')
        .doc(orgId)
        .collection('inventory');

    // --- DUPLICATE CHECK START ---
    final querySnapshot = await collection
        .where('billMachineNumber', isEqualTo: category.billMachineNumber)
        .get();

    for (var doc in querySnapshot.docs) {
      // If we find a doc with this number AND it's not the one we are currently editing
      if (category.id.isEmpty || doc.id != category.id) {
        throw Exception(
          'Bill Machine Number ${category.billMachineNumber} is already in use.',
        );
      }
    }
    // --- DUPLICATE CHECK END ---

    if (category.id.isEmpty) {
      final newDocRef = collection.doc();
      final categoryWithId = category.copyWithId(newDocRef.id);
      await newDocRef.set(categoryWithId.toJson());
    } else {
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
        .orderBy(
          'billMachineNumber',
        ) // Optional: order by bill machine number for easier management
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Category.fromFirestore(doc)).toList(),
        );
  }

  // Inside inventory_service.dart
  Future<void> deleteCategory(String orgId, String categoryId) async {
    try {
      // CHANGE 'categories' TO 'inventory' to match your screenshot
      await _db
          .collection('organizations')
          .doc(orgId)
          .collection(
            'inventory',
          ) // <--- This must match the screenshot exactly
          .doc(categoryId)
          .delete();

      print("Delete truly successful for ID: $categoryId");
    } catch (e) {
      print("Error deleting: $e");
      rethrow;
    }
  }
}

extension InventoryAnalytics on InventoryService {
  // Fetches sales and aggregates them by category for a specific date range
  Future<List<CategoryAnalytics>> getCategoryAnalytics(
    String orgId,
    DateTime start,
    DateTime end,
  ) async {
    final salesSnapshot = await _db
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    Map<String, CategoryAnalytics> aggregation = {};

    for (var doc in salesSnapshot.docs) {
      final items = doc.data()['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        final String catId = item['cat_id'] ?? 'unknown';
        final String name = item['categoryName'] ?? 'Unknown';
        final int qty = (item['qty'] as num? ?? 0).toInt();
        final double price = (item['finalPrice'] as num? ?? 0).toDouble();

        if (aggregation.containsKey(catId)) {
          var existing = aggregation[catId]!;
          aggregation[catId] = CategoryAnalytics(
            categoryId: catId,
            categoryName: name,
            totalQty: existing.totalQty + qty,
            totalRevenue: existing.totalRevenue + price,
          );
        } else {
          aggregation[catId] = CategoryAnalytics(
            categoryId: catId,
            categoryName: name,
            totalQty: qty,
            totalRevenue: price,
          );
        }
      }
    }
    return aggregation.values.toList();
  }
}
