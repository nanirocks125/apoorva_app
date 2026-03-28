import 'package:flutter/material.dart';

class AddCashflowScreen extends StatelessWidget {
  static const id = 'add_cashflow_screen';
  const AddCashflowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Cashflow')),
      body: Text('Add Cash Flow'),
    );
  }
}
