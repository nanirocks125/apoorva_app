import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/providers/auth_provider.dart';
import 'package:apoorva_app/screens/auth/login_screen.dart';
import 'package:apoorva_app/screens/dashboard/super_admin_dashboard.dart';
import 'package:apoorva_app/screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // We "watch" the AuthProvider. When status changes, this build method runs.
    final authProvider = context.watch<AuthProvider>();

    switch (authProvider.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case AuthStatus.unauthenticated:
        return const LoginScreen();

      case AuthStatus.authenticated:
        final user = authProvider.user;

        // Handle cases where auth is true but profile fetch failed
        if (user == null) return const LoginScreen();

        // Role-Based Routing
        if (user.role == .superAdmin) {
          return SuperAdminDashboard(user: user);
        } else {
          return HomeScreen(loggedInUser: user);
        }
    }
  }
}
