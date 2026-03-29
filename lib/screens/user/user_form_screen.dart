import 'package:apoorva_app/enum/form_mode.dart';
import 'package:apoorva_app/enum/system_role.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserFormScreen extends StatefulWidget {
  final AppUser? user;
  final FormMode mode;
  final Organization? org;

  const UserFormScreen({super.key, this.user, required this.mode, this.org});

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

  bool _isAuthorized = false;
  bool _checkingAccess = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _selectedSystemRole = widget.user?.role ?? SystemRole.standard;
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // 1. Allow if the user is a Global Super Admin
    final globalUser = await _service.getUserById(currentUser.uid);
    if (globalUser?.role == SystemRole.superAdmin) {
      if (mounted) {
        setState(() {
          _isAuthorized = true;
          _checkingAccess = false;
        });
      }
      return;
    }

    // 2. If creating staff for an org, check the local Org Role
    if (widget.org != null) {
      final orgId = widget.org!.id;
      final orgUserDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (orgUserDoc.exists) {
        final role = orgUserDoc.data()?['orgRole'] as UserRole?;
        // Check for 'owner' or 'manager' roles
        // ignore: unrelated_type_equality_checks
        if (role == UserRole.admin ||
            role == UserRole.manager ||
            role == UserRole.owner) {
          if (mounted) {
            setState(() {
              _isAuthorized = true;
              _checkingAccess = false;
            });
          }
          return;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isAuthorized = false;
        _checkingAccess = false;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    final newUserTemplate = AppUser(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _selectedSystemRole,
      createdAt: DateTime.now(),
    );

    try {
      // Action 1: Create Identity and root User Record (Always required)
      final createdUser = await _service.createIdentityAndProfile(
        user: newUserTemplate,
        password: 'Apoorva@123',
      );

      // Actions 2 & 3: Atomic Mapping (ONLY if organization is provided)
      // This fulfills the "Multi-Tenancy" requirement while allowing global admin flexibility.
      if (widget.org != null) {
        await _service.mapUserToOrganization(
          fullUser: createdUser,
          fullOrg: widget.org!,
          orgRole: _selectedSystemRole
              .name, // Using the same role for org mapping for simplicity
        );
      }

      if (mounted) {
        final message = widget.org != null
            ? 'Staff registered and mapped to ${widget.org!.name}'
            : 'Global user created successfully';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_person,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Permission Required',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'You don\'t have access to this page. Please contact your owner or manager for assistance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        // 3. Dynamic title based on mode and organization availability
        title: Text(
          widget.mode == FormMode.edit
              ? 'Edit Profile'
              : (widget.org != null
                    ? 'Register ${widget.org!.name} Staff' // Shows Org Name
                    : 'Create Global User'),
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
