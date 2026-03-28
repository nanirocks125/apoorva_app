import 'package:apoorva_app/screens/organization_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      print(
        'email: ${_emailController.text.trim()}, password: ${_passwordController.text.trim()}',
      );
      UserCredential user = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      print('after sign in methods: ${user.user?.email}');

      // Hard-coded Master Admin Email check
      if (user.user?.email == "nanirocks125@gmail.com") {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => OrganizationScreen()),
          );
        }
      } else {
        // Standard shop login logic
        print('Login successful for non-master admin: ${user.user?.email}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful, but not a master admin.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      print('error in login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please check your credentials.'),
        ),
      );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _emailController.text = "nanirocks125@gmail.com";
    _passwordController.text = "Nandam@125";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder for Apoorva Logo
              const Icon(Icons.storefront, size: 80, color: Color(0xFFFF5733)),
              const SizedBox(height: 16),
              Text(
                'Apoorva Polaris',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFF5733),
                ),
              ),
              const Text('Master Admin Login'),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Admin Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56, // Large touch target for speed
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5733),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login to Dashboard',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
