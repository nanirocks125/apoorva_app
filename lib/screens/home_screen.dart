import 'package:apoorva_app/screens/user/users_screen.dart';
import 'package:flutter/material.dart';
import 'package:apoorva_app/screens/organization_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Apoorva Polaris Admin'),
          backgroundColor: const Color(0xFFFF5733),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.storefront), text: 'Organizations'),
              Tab(icon: Icon(Icons.people_alt), text: 'Global Users'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OrganizationScreen(),
            UserScreen(), // This handles the generic list of all users
          ],
        ),
      ),
    );
  }
}
