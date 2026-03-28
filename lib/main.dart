import 'package:apoorva_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Ensure you've run 'flutterfire configure'

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ApoorvaApp());
}

class ApoorvaApp extends StatelessWidget {
  const ApoorvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apoorva POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Using the accent color from your Polaris schema
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5733),
          primary: const Color(0xFFFF5733),
        ),
        // Large touch targets for "Staff-Centric" design
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
