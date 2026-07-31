import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/model/category_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apoorva_app/localDB/category_local_db.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // 🟢 Crashlytics ఇంపోర్ట్

class InventoryService {
  final FirebaseFirestore _db;

  // ఆఖరిసారిగా సింక్ అయిన టైమ్‌ని ట్రాక్ చేయడానికి
  DateTime? lastRefreshTime;

  InventoryService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  // 🟢 1. రిమోట్ నుంచి లేటెస్ట్ కేటగిరీలను తెచ్చి లోకల్ SQLite లో అప్‌డేట్ చేయడం (Sync & Refresh)
  Future<List<Category>> fetchAndRefreshLocalCategories(String orgId) async {
    try {
      FirebaseCrashlytics.instance.log(
        'Fetching inventory from remote for org: $orgId',
      );

      final snapshot = await _db
          .collection('organizations')
          .doc(orgId)
          .collection('inventory')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final remoteCategories = snapshot.docs.map((doc) {
          final cat = Category.fromFirestore(doc);
          return cat.copyWithId(doc.id);
        }).toList();

        // లోకల్ SQLite లో క్యాష్ చేయడం
        await CategoryLocalDatabase.instance.cacheCategories(remoteCategories);
        lastRefreshTime = DateTime.now(); // టైమ్ అప్‌డేట్ చేయడం

        FirebaseCrashlytics.instance.log(
          'Local DB successfully refreshed from remote. Total items: ${remoteCategories.length}',
        );
        print("Local DB successfully refreshed from remote!");
        return remoteCategories;
      } else {
        FirebaseCrashlytics.instance.log(
          'Remote inventory is empty for org: $orgId',
        );
      }
    } catch (e, stackTrace) {
      // 🟢 నాన్-ఫాటల్ ఎర్రర్‌ని క్రాష్‌లిటిక్స్‌కి రిపోర్ట్ చేయడం
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to fetch from remote, using local cache',
      );
      print("Failed to fetch from remote, using local cache: $e");
    }

    // నెట్ లేకపోతే లేదా ఎర్రర్ వస్తే లోకల్ డేటాయే రిటర్న్ చేయడం
    FirebaseCrashlytics.instance.log('Falling back to local SQLite cache');
    return await CategoryLocalDatabase.instance.getCachedCategories();
  }

  // 🟢 2. నేరుగా లోకల్ DB నుండి కేటగిరీలను పొందడం (Zero Cost Read)
  Future<List<Category>> getCachedCategories() async {
    FirebaseCrashlytics.instance.log(
      'Reading categories directly from local SQLite DB',
    );
    return await CategoryLocalDatabase.instance.getCachedCategories();
  }

  Future<void> saveCategory(String orgId, Category category) async {
    FirebaseCrashlytics.instance.log(
      'Saving category: ${category.name} (Machine No: ${category.billMachineNumber})',
    );

    final collection = _db
        .collection('organizations')
        .doc(orgId)
        .collection('inventory');

    // --- DUPLICATE CHECK START ---
    final querySnapshot = await collection
        .where('billMachineNumber', isEqualTo: category.billMachineNumber)
        .get();

    for (var doc in querySnapshot.docs) {
      if (category.id.isEmpty || doc.id != category.id) {
        final exception = Exception(
          'Bill Machine Number ${category.billMachineNumber} is already in use.',
        );
        FirebaseCrashlytics.instance.recordError(
          exception,
          null,
          reason: 'Duplicate bill machine number error',
        );
        throw exception;
      }
    }
    // --- DUPLICATE CHECK END ---

    if (category.id.isEmpty) {
      final newDocRef = collection.doc();
      final categoryWithId = category.copyWithId(newDocRef.id);
      await newDocRef.set(categoryWithId.toJson());

      // లోకల్ DB లో కూడా సేవ్ చేయడం
      await CategoryLocalDatabase.instance.cacheCategories([categoryWithId]);
      FirebaseCrashlytics.instance.log(
        'New category created and cached locally: ${categoryWithId.id}',
      );
    } else {
      await collection
          .doc(category.id)
          .set(category.toJson(), SetOptions(merge: true));

      // లోకల్ DB లో అప్‌డేట్ చేయడం
      await CategoryLocalDatabase.instance.cacheCategories([category]);
      FirebaseCrashlytics.instance.log(
        'Category updated and cached locally: ${category.id}',
      );
    }
  }

  // పాత గ్లోబల్ గెటర్ (అవసరమైతే బ్యాక్‌వర్డ్ కంప్యాటిబిలిటీ కోసం)
  Stream<List<Category>> getCategories(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('inventory')
        .orderBy('billMachineNumber')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => Category.fromFirestore(doc)).toList(),
        );
  }

  Future<void> deleteCategory(String orgId, String categoryId) async {
    try {
      FirebaseCrashlytics.instance.log(
        'Attempting to delete category ID: $categoryId',
      );

      await _db
          .collection('organizations')
          .doc(orgId)
          .collection('inventory')
          .doc(categoryId)
          .delete();

      FirebaseCrashlytics.instance.log(
        'Delete truly successful for ID: $categoryId',
      );
      print("Delete truly successful for ID: $categoryId");
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Error deleting category ID: $categoryId',
      );
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
    FirebaseCrashlytics.instance.log(
      'Fetching category analytics for org: $orgId',
    );

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
