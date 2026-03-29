import 'package:apoorva_app/services/organization_service.dart';
import 'package:flutter/material.dart';

class CategoryForm extends StatefulWidget {
  final String orgId;
  final Map<String, dynamic>? initialData;
  const CategoryForm({super.key, required this.orgId, this.initialData});

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _socialController = TextEditingController();
  bool _isHotkey = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name'];
      _stockController.text = widget.initialData!['current_stock'].toString();
      _socialController.text = widget.initialData!['social_media_link'] ?? '';
      _isHotkey = widget.initialData!['is_hotkey'] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Category Name (e.g. Bangles)',
            ),
          ),
          TextField(
            controller: _stockController,
            decoration: const InputDecoration(labelText: 'Initial Stock Count'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _socialController,
            decoration: const InputDecoration(
              labelText: 'Social Media Link (Instagram)',
            ),
          ),
          SwitchListTile(
            title: const Text('Pin to POS Hotkeys'),
            value: _isHotkey,
            onChanged: (val) => setState(() => _isHotkey = val),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await OrganizationService().saveCategory(widget.orgId, {
                'name': _nameController.text,
                'current_stock': int.parse(_stockController.text),
                'social_media_link': _socialController.text,
                'is_hotkey': _isHotkey,
                'last_sold_date':
                    widget.initialData?['last_sold_date'] ??
                    DateTime.now().toIso8601String(),
              }, catId: widget.initialData?['id']);
              Navigator.pop(context);
            },
            child: const Text('Save Category'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
