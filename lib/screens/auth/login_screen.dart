import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _emailController.text = "lavanya@gmail.com";
      _passwordController.text = "Apoorva@123";
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.storefront,
                  size: 80,
                  color: Color(0xFFFF5733),
                ),
                const SizedBox(height: 16),
                Text('Apoorva', style: _logoStyle(context)),
                const Text('Login'),
                const SizedBox(height: 40),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 32),
                _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- LOGIC EXTENSION ---
// We extend the State class specifically so we have access to context, setState, and controllers.
extension _LoginLogic on _LoginScreenState {
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      print('successful sign in');

      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: authProvider.user,
        );
      }
      print('after navigation');
    } catch (e) {
      print('error in login ${e.toString()}');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (context.mounted) setState(() => _isLoading = false);
    }
  }

  // Helper UI methods can also live here to keep the build method even cleaner
  TextStyle? _logoStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .headlineMedium
      ?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFFF5733));

  Widget _buildEmailField() => TextFormField(
    controller: _emailController,
    decoration: const InputDecoration(labelText: 'Email'),
    keyboardType: TextInputType.emailAddress,
    validator: (v) =>
        (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
  );

  Widget _buildPasswordField() => TextFormField(
    controller: _passwordController,
    decoration: const InputDecoration(labelText: 'Password'),
    obscureText: true,
    validator: (v) => (v == null || v.length < 6) ? 'Password too short' : null,
  );

  Widget _buildLoginButton() => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF5733),
        foregroundColor: Colors.white,
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Login to Dashboard', style: TextStyle(fontSize: 18)),
    ),
  );
}
