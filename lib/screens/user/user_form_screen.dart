import 'package:apoorva_app/enum/form_mode.dart';
import 'package:apoorva_app/enum/system_role.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/services/user_service.dart';
import 'package:flutter/material.dart';

class UserFormScreen extends StatefulWidget {
  final AppUser? user;
  final FormMode mode;

  const UserFormScreen({super.key, this.user, required this.mode});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _service = UserService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  SystemRole _selectedSystemRole = SystemRole.standard;
  bool _isLoading = false; // 1. Add this state variable

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _selectedSystemRole = widget.user?.role ?? SystemRole.standard;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading)
      return; // 2. Block if loading

    setState(() => _isLoading = true); // 3. Start loading

    final newUser = AppUser(
      id: widget.user?.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _selectedSystemRole,
      orgIds:
          widget.user?.orgIds ?? [], // Preserves existing mappings if editing
      createdAt: widget.user?.createdAt ?? DateTime.now(),
    );

    try {
      // Save to the root /users collection
      await _service.createIdentityAndProfile(
        user: newUser,
        password: 'Apoorva@123',
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false); // 4. Stop loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == FormMode.create
              ? 'Create Global User'
              : 'Edit Profile',
        ),
        backgroundColor: const Color(0xFFFF5733),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v!.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SystemRole>(
              value: _selectedSystemRole,
              decoration: const InputDecoration(
                labelText: 'System Role',
                prefixIcon: Icon(Icons.security),
              ),
              items: SystemRole.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedSystemRole = val!),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5733),
                ),
                onPressed: _submit,
                child: Text(
                  widget.mode == FormMode.create
                      ? 'Create Identity'
                      : 'Save Changes',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
