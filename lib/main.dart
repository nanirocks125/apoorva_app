import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/screens/auth/login_screen.dart';
import 'package:apoorva_app/screens/customer/customer_history_screen.dart';
import 'package:apoorva_app/screens/customer/customer_screen.dart';
import 'package:apoorva_app/screens/home_screen.dart';
import 'package:apoorva_app/screens/inventory/inventory_screen.dart';
import 'package:apoorva_app/screens/organization/organization_details_screen.dart';
import 'package:apoorva_app/screens/organization/organization_form_screen.dart';
import 'package:apoorva_app/screens/organization/organization_selection_screen.dart';
import 'package:apoorva_app/screens/dashboard/super_admin_dashboard.dart';
import 'package:apoorva_app/screens/pos_screen.dart';
import 'package:apoorva_app/screens/reports_screen.dart';
import 'package:apoorva_app/screens/sales_history_screen.dart';
import 'package:apoorva_app/screens/scripts/scripts_screen.dart';
import 'package:apoorva_app/screens/user/users_screen.dart';
import 'package:apoorva_app/screens/whatsapp_status_queue_screen.dart';
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
      title: 'Apoorva Retail Management',
      initialRoute: '/login',
      // 2. Named Routes Table
      routes: {'/login': (context) => const LoginScreen()},

      // 3. Dynamic Route Handling (For screens requiring objects like Organization)
      onGenerateRoute: (settings) {
        // --- Handle /home route ---
        if (settings.name == '/home') {
          final user =
              settings.arguments
                  as AppUser; // Extract the user passed from Login
          return MaterialPageRoute(
            builder: (context) => HomeScreen(loggedInUser: user),
          );
        }

        if (settings.name == '/staff') {
          final org = settings.arguments as Organization;
          return MaterialPageRoute(builder: (context) => UserScreen(org: org));
        }

        if (settings.name == '/reports') {
          final org = settings.arguments as Organization;
          return MaterialPageRoute(
            builder: (context) => ReportsScreen(orgId: org.id),
          );
        }

        if (settings.name == '/customers') {
          final org = settings.arguments as Organization;
          return MaterialPageRoute(
            builder: (context) => CustomersScreen(orgId: org.id),
          );
        }

        if (settings.name == '/customer-sales-history') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CustomerHistoryScreen(
              orgId: args['orgId'],
              customerId: args['customerId'],
              customerName: args['customerName'],
              customerPhone: args['customerPhone'],
            ),
          );
        }

        if (settings.name == '/scripts') {
          final org = settings.arguments as Organization;
          return MaterialPageRoute(
            builder: (context) => ScriptsScreen(orgId: org.id),
          );
        }
        if (settings.name == '/whatsapp-queue') {
          final org = settings.arguments as Organization;
          return MaterialPageRoute(
            builder: (context) => WhatsappQueueScreen(orgId: org.id),
          );
        }

        if (settings.name == '/pos') {
          final orgId =
              settings.arguments
                  as String; // Extract the user passed from Login
          return MaterialPageRoute(
            builder: (context) => PosScreen(orgId: orgId),
          );
        }

        if (settings.name == '/sales-history') {
          final org = settings.arguments as Organization;
          return MaterialPageRoute(
            builder: (context) => SalesHistoryScreen(orgId: org.id),
          );
        }

        if (settings.name == '/inventory') {
          final org = settings.arguments as Organization;
          return MaterialPageRoute(
            builder: (context) => InventoryScreen(orgId: org.id),
          );
        }

        // --- Handle /super-admin route ---
        if (settings.name == '/super-admin') {
          final user = settings.arguments as AppUser;
          return MaterialPageRoute(
            builder: (context) => SuperAdminDashboard(user: user),
          );
        }
        if (settings.name == '/org-form') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) =>
                OrganizationFormScreen(mode: args['mode'], org: args['org']),
          );
        }

        if (settings.name == '/org-details') {
          final org = settings.arguments as Organization;
          return MaterialPageRoute(
            builder: (context) => OrganizationDetailsScreen(org: org),
          );
        }

        // --- Handle /org-selection route ---
        if (settings.name == '/org-selection') {
          final user = settings.arguments as AppUser;
          return MaterialPageRoute(
            builder: (context) => OrganizationSelectionScreen(user: user),
          );
        }

        return null; // Fallback to routes table
      },
      // );
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
