import 'package:apoorva_app/components/category_form.dart';
import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/services/inventory_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class InventoryScreen extends StatefulWidget {
  final InventoryService _inventoryService;
  InventoryScreen({super.key, InventoryService? inventoryService})
    : _inventoryService = inventoryService ?? InventoryService();

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Category> _items = [];
  bool _isLoading = true;
  String _lastRefreshText = "Never";

  @override
  void initState() {
    super.initState();
    _loadLocalInventory();
  }

  // లోకల్ DB నుండి డేటా తెచ్చుకోవడం
  Future<void> _loadLocalInventory() async {
    setState(() => _isLoading = true);
    final data = await widget._inventoryService.getCachedCategories();

    if (widget._inventoryService.lastRefreshTime != null) {
      _lastRefreshText = DateFormat(
        'hh:mm a, dd MMM',
      ).format(widget._inventoryService.lastRefreshTime!);
    }

    setState(() {
      _items = data;
      _isLoading = false;
    });
  }

  // Pull-to-Refresh & Sync from Remote via InventoryService
  Future<void> _handleRefresh() async {
    final organization = Provider.of<OrganizationProvider>(
      context,
      listen: false,
    ).currentOrganization;

    if (organization == null) return;

    setState(() => _isLoading = true);
    try {
      await widget._inventoryService.fetchAndRefreshLocalCategories(
        organization.id,
      );
      await _loadLocalInventory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventory refreshed successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final organization = Provider.of<OrganizationProvider>(
      context,
    ).currentOrganization;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inventory Management', style: TextStyle(fontSize: 18)),
            Text(
              'Last Synced: $_lastRefreshText',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _handleRefresh,
            tooltip: 'Sync from Remote',
          ),
        ],
      ),
      body: (organization == null)
          ? const Center(child: Text('No organization selected'))
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 250),
                        Center(
                          child: Text(
                            'No categories found. Pull down to refresh or tap "+" to add.',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.isHotkey
                                  ? Colors.orange
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.category,
                                color: item.isHotkey
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            ),
                            title: Text(
                              '${item.billMachineNumber}. ${item.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Stock: ${item.currentStock} | Hotkey: ${item.isHotkey ? "Yes" : "No"}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _showCategoryForm(context, item: item),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, item),
                                ),
                              ],
                            ),
                            onTap: () => _showCategoryForm(context, item: item),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryForm(BuildContext context, {Category? item}) {
    final organization = Provider.of<OrganizationProvider>(
      context,
      listen: false,
    ).currentOrganization;

    if (organization == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategoryForm(
        orgId: organization.id,
        category: item,
        inventoryService: null,
      ),
    ).then((_) => _loadLocalInventory());
  }

  Future<void> _confirmDelete(BuildContext context, Category item) async {
    final organization = Provider.of<OrganizationProvider>(
      context,
      listen: false,
    ).currentOrganization;

    if (organization == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget._inventoryService.deleteCategory(organization.id, item.id);
        await _handleRefresh(); // రిఫ్రెష్ చేసి లోకల్ DB ని అప్‌డేట్ చేయడం

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${item.name} deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting category: $e')),
          );
        }
      }
    }
  }
}
