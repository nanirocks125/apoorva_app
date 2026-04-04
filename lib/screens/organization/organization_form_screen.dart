import 'package:apoorva_app/enum/form_mode.dart';
import 'package:apoorva_app/model/account.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:flutter/material.dart';
import 'package:apoorva_app/enum/account_type.dart';
import 'package:apoorva_app/services/organization_service.dart';

class OrganizationFormScreen extends StatefulWidget {
  final Organization? org; // Changed from Map to Model
  final FormMode mode;
  final OrganizationService? orgService; // Add this
  const OrganizationFormScreen({
    super.key,
    this.org,
    required this.mode,
    this.orgService, // Add this
  });

  @override
  State<OrganizationFormScreen> createState() => _OrganizationFormScreenState();
}

class _OrganizationFormScreenState extends State<OrganizationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final OrganizationService _orgService =
      widget.orgService ?? OrganizationService();

  late TextEditingController _nameController;
  late TextEditingController _minVersionController;
  late TextEditingController _cashController;
  late TextEditingController _bankController;
  String _status = 'Active';

  bool get isViewOnly => widget.mode == FormMode.view;
  bool get isEdit => widget.mode == FormMode.edit;

  @override
  void initState() {
    super.initState();
    // Initialize using model properties
    _nameController = TextEditingController(text: widget.org?.name ?? '');
    _minVersionController = TextEditingController(
      text: widget.org?.minVersion ?? '1.0.0',
    );
    _status = widget.org?.status ?? 'Active';

    // Seed values for creation mode
    _cashController = TextEditingController(text: '0');
    _bankController = TextEditingController(text: '0');
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (widget.mode == FormMode.create) {
        // Create initial accounts list for the array
        final initialAccounts = [
          Account(
            name: 'Cash Account',
            type: AccountType.cash,
            currentBalance: double.parse(_cashController.text),
          ),
        ];

        final newOrg = Organization(
          name: _nameController.text.trim(),
          status: _status,
          createdAt: DateTime.now(),
          minVersion: _minVersionController.text.trim(),
          accounts: initialAccounts,
        );

        await _orgService.createOrganization(newOrg);
      } else if (isEdit) {
        // Update existing model with new values
        final updatedOrg = Organization(
          id: widget.org!.id,
          name: _nameController.text.trim(),
          status: _status,
          createdAt: widget.org!.createdAt,
          minVersion: _minVersionController.text.trim(),
          accounts: widget.org!.accounts, // Keep existing accounts
        );

        await _orgService.updateOrganization(updatedOrg);
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == FormMode.create ? 'New Shop' : 'Shop Settings',
        ),
        backgroundColor: const Color(0xFFFF5733),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: isViewOnly ? null : _buildBottomNavBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildHeader('Shop Identity'),
            TextFormField(
              controller: _nameController,
              enabled: !isViewOnly,
              decoration: const InputDecoration(labelText: 'Organization Name'),
              validator: (v) => v!.isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 24),

            if (widget.mode == FormMode.create) ...[
              _buildHeader('Financial Seeding'),
              const Text(
                'Initialize balances for the Net Cash Dashboard.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildBalanceField(_cashController, 'Initial Cash'),
                  const SizedBox(width: 16),
                  _buildBalanceField(_bankController, 'Initial Bank'),
                ],
              ),
              const SizedBox(height: 24),
            ],

            _buildHeader('System Configuration'),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Operational Status',
              ),
              items: [
                'Active',
                'Inactive',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: isViewOnly
                  ? null
                  : (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minVersionController,
              enabled: !isViewOnly,
              decoration: const InputDecoration(
                labelText: 'Minimum App Version',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildBalanceField(TextEditingController controller, String label) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixText: '₹'),
        keyboardType: TextInputType.number,
        textInputAction: .done,
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5733),
          ),
          onPressed: _saveForm,
          child: Text(
            isEdit ? 'Update Shop' : 'Seed & Launch Shop',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
