import 'package:apoorva_app/components/category_form.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/services/inventory_service.dart';
import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  final String orgId;
  const InventoryScreen({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Management')),
      body: StreamBuilder<List<Category>>(
        stream: InventoryService().getCategories(orgId),
        builder: (context, snapshot) {
          // 1. Check for Errors (Critical for Permission Denied issues)
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 2. Check Connection State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          // 3. Handle Empty State
          if (items.isEmpty) {
            return const Center(
              child: Text('No categories found. Tap "+" to add stock.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.isHotkey
                        ? Colors.orange
                        : Colors.grey.shade200,
                    child: Icon(
                      Icons.category,
                      color: item.isHotkey ? Colors.white : Colors.grey,
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Stock: ${item.currentStock} | Hotkey: ${item.isHotkey ? "Yes" : "No"}',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => {_showCategoryForm(context, item: item)},
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryForm(BuildContext context, {Category? item}) {
    print(
      'showing form for item: ${item?.name ?? "New Category"}',
    ); // Debug Log
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategoryForm(orgId: orgId, category: item),
    );
  }
}
