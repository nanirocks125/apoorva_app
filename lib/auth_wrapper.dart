import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/providers/auth_provider.dart';
import 'package:apoorva_app/screens/auth/login_screen.dart';
import 'package:apoorva_app/screens/dashboard/super_admin_dashboard.dart';
import 'package:apoorva_app/screens/home_screen.dart';
import 'package:apoorva_app/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Connection స్టేట్ చెక్ చేయడం
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. యూజర్ లాగిన్ అవ్వకపోతే LoginScreen కి పంపడం
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 3. యూజర్ లాగిన్ అయి ఉంటే, Firestore నుండి రోల్ ఫెచ్ చేయడం
        return FutureBuilder<AppUser?>(
          future: UserService().getUserById(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final loggedInUser = userSnapshot.data;

            if (loggedInUser == null) {
              return const LoginScreen(); // ప్రొఫైల్ లేకపోతే మళ్ళీ లాగిన్
            }

            // Global State అప్‌డేట్ చేయడం (AuthProvider)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Provider.of<AuthProvider>(
                context,
                listen: false,
              ).setUser(loggedInUser);
            });

            // 4. Role-Based Navigation Logic
            if (loggedInUser.role == 'super_admin') {
              return SuperAdminDashboard(user: loggedInUser);
            } else {
              // సాధారణ స్టాఫ్ లేదా అడ్మిన్ అయితే Home కి
              return HomeScreen(loggedInUser: loggedInUser);
            }
          },
        );
      },
    );
  }
}
