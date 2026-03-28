import 'package:apoorva_app/screens/add_cashflow.dart';
import 'package:apoorva_app/screens/cashflow.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:apoorva_app/screens/welcome_screen.dart';
import 'package:apoorva_app/screens/login_screen.dart';
import 'package:apoorva_app/screens/registration_screen.dart';
import 'package:apoorva_app/screens/chat_screen.dart';
import 'firebase_options.dart'; // 1. Import the new file
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  // 1. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase with platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(ApoorvaApp());
}

class ApoorvaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 2. While waiting for the stream, show a loading spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 3. If the user is logged in, show ChatScreen directly
          if (snapshot.hasData) {
            return AddCashflowScreen();
          }
          // 4. Otherwise, show the WelcomeScreen
          return WelcomeScreen();
        },
      ),
      routes: {
        WelcomeScreen.id: (context) => WelcomeScreen(),
        LoginScreen.id: (context) => LoginScreen(),
        RegistrationScreen.id: (context) => RegistrationScreen(),
        ChatScreen.id: (context) => ChatScreen(),
        CashflowScreen.id: (context) => CashflowScreen(),
        AddCashflowScreen.id: (context) => AddCashflowScreen(),
      },
    );
  }
}
