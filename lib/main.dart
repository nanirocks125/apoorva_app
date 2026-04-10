import 'package:apoorva_app/auth_wrapper.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/model/user/app_user.dart';
import 'package:apoorva_app/modules/customer/customer_analytics/customer_analytics_screen.dart';
import 'package:apoorva_app/modules/customer/customer_details_screen.dart';
import 'package:apoorva_app/modules/daily-summary-report/daily_summary_report.dart';
import 'package:apoorva_app/modules/daily-summary-report/daily_summary_screen.dart';
import 'package:apoorva_app/providers/auth_provider.dart';
import 'package:apoorva_app/providers/cart_provider.dart';
import 'package:apoorva_app/providers/organization_provider.dart';
import 'package:apoorva_app/screens/auth/login_screen.dart';
import 'package:apoorva_app/screens/customer/customer_history_screen.dart';
import 'package:apoorva_app/screens/customer/customer_screen.dart';
import 'package:apoorva_app/screens/dashboard/organization_dashboard_screen.dart';
import 'package:apoorva_app/screens/home/home_screen.dart';
import 'package:apoorva_app/screens/inventory/inventory_screen.dart';
import 'package:apoorva_app/screens/profile/profile_screen.dart';
import 'package:apoorva_app/screens/organization/organization_details_screen.dart';
import 'package:apoorva_app/screens/organization/organization_form_screen.dart';
import 'package:apoorva_app/screens/organization/organization_screen.dart';
import 'package:apoorva_app/screens/organization/organization_selection_screen.dart';
import 'package:apoorva_app/screens/dashboard/super_admin_dashboard.dart';
import 'package:apoorva_app/screens/pos_screen.dart';
import 'package:apoorva_app/screens/reports_screen.dart';
import 'package:apoorva_app/screens/sales_history_screen.dart';
import 'package:apoorva_app/screens/scripts/scripts_screen.dart';
import 'package:apoorva_app/screens/home/user/users_screen.dart';
import 'package:apoorva_app/screens/whatsapp_status_queue_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/firebase_options_dev.dart' as dev;
import 'package:apoorva_app/firebase_options_prod.dart' as prod;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Check if any Firebase apps are already initialized
  try {
    // బిల్డ్ మోడ్ ని బట్టి ఆప్షన్స్ సెలెక్ట్ చేయడం
    final options = kReleaseMode
        ? prod.DefaultFirebaseOptions.currentPlatform
        : dev.DefaultFirebaseOptions.currentPlatform;

    await Firebase.initializeApp(options: options);
  } catch (e) {
    // If it fails because it already exists, we check if it's actually there
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized, skipping...');
    } else {
      // If it's a different error, rethrow it so you can see it
      rethrow;
    }
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // 2. Organization Provider depends on Auth Provider
        ChangeNotifierProxyProvider<AuthProvider, OrganizationProvider>(
          create: (_) => OrganizationProvider(),
          update: (context, authProvider, previousOrgProvider) {
            // This is the magic link: Every time auth changes (like after a successful login),
            // this update triggers, passing the AppUser to fetch the specific Org.
            previousOrgProvider?.updateForUser(authProvider.user);
            return previousOrgProvider!;
          },
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const ApoorvaApp(),
    ),
  );
}

class ApoorvaApp extends StatelessWidget {
  const ApoorvaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apoorva Retail Management',
      home: const AuthWrapper(),
      // 2. Named Routes Table
      routes: {
        '/login': (context) => const LoginScreen(),
        '/users': (context) => UserScreen(),
        '/organizations': (context) => OrganizationScreen(),
        '/dashboard': (context) => OrganizationDashboard(),
        '/sales_summary': (context) => SalesSummaryScreen(),
        '/customer_analytics': (context) => CustomerAnalyticsScreen(),
      },

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
          // final org = settings.arguments as Organization;
          return MaterialPageRoute(builder: (context) => CustomersScreen());
        }

        if (settings.name == '/customer-sales-history') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CustomerHistoryScreen(
              orgId: args['orgId'],
              customer: args['customer'] as Customer,
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
          final organization =
              settings.arguments
                  as Organization; // Extract the user passed from Login
          return MaterialPageRoute(
            builder: (context) => PosScreen(organization: organization),
          );
        }

        // if (settings.name == '/sales-history') {
        //   final org = settings.arguments as Organization;
        //   return MaterialPageRoute(
        //     builder: (context) => SalesHistoryScreen(orgId: org.id),
        //   );
        // }

        if (settings.name == '/inventory') {
          return MaterialPageRoute(builder: (context) => InventoryScreen());
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

        if (settings.name == '/profile') {
          final user = settings.arguments as AppUser?;
          if (user == null) {
            // Redirect to login or show error
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          }
          return MaterialPageRoute(
            builder: (context) => ProfileScreen(user: user),
          );
        }

        if (settings.name == '/customer-details') {
          final customer = settings.arguments as Customer;
          return MaterialPageRoute(
            builder: (context) => CustomerDetailsScreen(customer: customer),
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
      // home: const LoginScreen(),
    );
  }
}
