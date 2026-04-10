// screens/customer_form_screen.dart
import 'package:flutter/material.dart';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/services/customer_service.dart';
import 'package:intl/intl.dart';

class CustomerFormScreen extends StatefulWidget {
  final String orgId;
  final Customer?
  existingCustomer; // Null means CREATE NEW, Provided means EDIT
  final CustomerService _customerService; // ✅ Add this

  CustomerFormScreen({
    super.key,
    required this.orgId,
    this.existingCustomer,
    CustomerService? customerService, // ✅ Add this
  }) : _customerService = customerService ?? CustomerService();

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  // State variables for the dates
  late DateTime _createdAt;
  DateTime? _lastPurchaseDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingCustomer?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.existingCustomer?.phone ?? '',
    );

    // Initialize dates from the existing customer, or set defaults for a new one
    _createdAt = widget.existingCustomer?.createdAt ?? DateTime.now();
    _lastPurchaseDate = widget.existingCustomer?.lastPurchaseDate;
  }

  // Helper method to open the Date Picker
  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime> onDatePicked,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2010), // Set your business inception year here
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      onDatePicked(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final customerToSave = Customer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        // Use the newly selected dates from the state
        lastPurchaseDate: _lastPurchaseDate,
        createdAt: _createdAt,
        // Preserve financial stats
        totalSales: widget.existingCustomer?.totalSales ?? 0,
        totalAmountSpent: widget.existingCustomer?.totalAmountSpent ?? 0.0,
      );

      await widget._customerService.saveCustomer(widget.orgId, customerToSave);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCustomer != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Customer' : 'New Customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              enabled: !isEditing,
              validator: (v) => v!.length < 10 ? 'Enter valid phone' : null,
            ),
            if (isEditing)
              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Text(
                  'Phone number cannot be changed as it is the primary ID.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),

            // --- DATE PICKER 1: Customer Since (CreatedAt) ---
            InkWell(
              onTap: () => _pickDate(
                initialDate: _createdAt,
                onDatePicked: (date) => setState(() => _createdAt = date),
              ),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Customer Since',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd MMM yyyy').format(_createdAt)),
                    const Icon(Icons.calendar_month, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- DATE PICKER 2: Last Purchase Date ---
            InkWell(
              onTap: () => _pickDate(
                initialDate: _lastPurchaseDate,
                onDatePicked: (date) =>
                    setState(() => _lastPurchaseDate = date),
              ),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Last Purchase Date (Optional)',
                  border: const OutlineInputBorder(),
                  // Add a clear button if a date is set, otherwise show the calendar icon
                  suffixIcon: _lastPurchaseDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () =>
                              setState(() => _lastPurchaseDate = null),
                        )
                      : const Icon(Icons.calendar_month, color: Colors.grey),
                ),
                child: Text(
                  _lastPurchaseDate != null
                      ? DateFormat('dd MMM yyyy').format(_lastPurchaseDate!)
                      : 'Not set (No purchases yet)',
                  style: TextStyle(
                    color: _lastPurchaseDate != null
                        ? Colors.black87
                        : Colors.grey,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Customer'),
            ),
          ],
        ),
      ),
    );
  }
}
