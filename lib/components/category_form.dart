import 'package:apoorva_app/model/category/category.dart';
import 'package:apoorva_app/services/inventory_service.dart'; // Updated Service
import 'package:flutter/material.dart';

class CategoryForm extends StatefulWidget {
  final String orgId;
  final Category? category; // Fixed spelling from 'catogory'

  const CategoryForm({super.key, required this.orgId, this.category});

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _billMachineNumberController = TextEditingController();
  bool _isHotkey = false;

  @override
  void initState() {
    super.initState();
    // Populate fields if we are editing an existing category
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _stockController.text = widget.category!.currentStock.toString();
      _billMachineNumberController.text = widget.category!.billMachineNumber
          .toString();
      _isHotkey = widget.category!.isHotkey;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Handles keyboard overlap automatically
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Inventory Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Category Name (e.g. Bangles)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _stockController,
            decoration: const InputDecoration(
              labelText: 'Initial Stock Count',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          // --- Bill Machine Number (New Field) ---
          TextField(
            controller: _billMachineNumberController,
            decoration: const InputDecoration(
              labelText: 'Bill Machine Number / Code',
              hintText: 'e.g. 0 or 12',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.confirmation_number_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Pin to POS Hotkeys'),
            subtitle: const Text(
              'Shows this category on the main sales screen',
            ),
            value: _isHotkey,
            onChanged: (val) => setState(() => _isHotkey = val),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFFFF5733),
            ),
            onPressed: () async {
              // 1. Create the typed Model object
              // If editing, use the existing ID; if new, use 0 to trigger transaction
              final updatedCategory = Category(
                id: widget.category?.id ?? '', // Use string ID
                name: _nameController.text,
                currentStock: int.tryParse(_stockController.text) ?? 0,
                isHotkey: _isHotkey,
                lastSoldDate: widget.category?.lastSoldDate,
                billMachineNumber:
                    int.tryParse(_billMachineNumberController.text) ?? 0,
              );

              try {
                await InventoryService().saveCategory(
                  widget.orgId,
                  updatedCategory,
                );
                if (mounted) Navigator.pop(context); // Close form on success
              } catch (e) {
                // Extract the message from Exception('...')
                final errorMessage = e.toString().replaceAll('Exception: ', '');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Save Category',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
