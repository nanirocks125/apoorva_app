import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/localDB/category_local_db.dart';
import 'package:apoorva_app/services/inventory_service.dart';

abstract class CategoryRepository {
  // Add orgId parameter to all methods
  Future<List<Category>> getCategories(
    String orgId, {
    bool forceRefresh = false,
  });
  Future<void> saveCategory(String orgId, Category category);
  Future<void> deleteCategory(String orgId, String categoryId);
}

class CategoryRepositoryImpl implements CategoryRepository {
  final InventoryService remoteService;
  final CategoryLocalDatabase localDb;

  // orgId is no longer needed in the constructor
  CategoryRepositoryImpl({required this.remoteService, required this.localDb});

  @override
  Future<List<Category>> getCategories(
    String orgId, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      try {
        final remoteCategories = await remoteService.fetchCategories(orgId);
        await localDb.cacheCategories(remoteCategories);
        return remoteCategories;
      } catch (e) {
        print("Apoorva - Remote fetch failed, using local cache: $e");
      }
    }
    return await localDb.getCachedCategories();
  }

  @override
  Future<void> saveCategory(String orgId, Category category) async {
    final savedCategory = await remoteService.saveCategory(orgId, category);
    await localDb.cacheCategories([savedCategory]);
  }

  @override
  Future<void> deleteCategory(String orgId, String categoryId) async {
    await remoteService.deleteCategory(orgId, categoryId);
  }
}
