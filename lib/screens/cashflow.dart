import 'package:apoorva_app/screens/welcome_screen.dart';
import 'package:flutter/material.dart';

class CashflowScreen extends StatelessWidget {
  static const String id = 'cashflow_screen';

  const CashflowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cashflow'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, WelcomeScreen.id);
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: Text('Cash flow'),
    );
  }
}
