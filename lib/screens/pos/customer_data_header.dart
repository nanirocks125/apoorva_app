import 'dart:async';
import 'package:apoorva_app/model/customer/customer.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/services/customer_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomerDataHeader extends StatefulWidget {
  final CustomerService? customerService;
  const CustomerDataHeader({super.key, this.customerService});
  @override
  State<CustomerDataHeader> createState() => CustomerDataHeaderState();
}

class CustomerDataHeaderState extends State<CustomerDataHeader> {
  List<Customer> _allCustomers = []; // లోకల్ కాష్ డేటా
  List<Customer> _searchResults = []; // సెర్చ్ రిజల్ట్స్
  StreamSubscription<List<Customer>>? _customerSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 1. యాప్ ఓపెన్ అవ్వగానే కస్టమర్ల లిస్ట్‌ను ఒకేసారి బ్యాక్‌గ్రౌండ్‌లో లోడ్ చేయడం
    if (_customerSubscription == null) {
      final provider = Provider.of<PosProvider>(context, listen: false);
      final service = widget.customerService ?? CustomerService();
      _customerSubscription = service.getCustomers(provider.orgId).listen((
        customers,
      ) {
        if (mounted) {
          setState(() {
            _allCustomers = customers;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _customerSubscription?.cancel();
    super.dispose();
  }

  // 2. లోకల్ మెమరీ సెర్చ్ లాజిక్ (100% Case-Insensitive)
  void _onNameChanged(String val) {
    if (val.length >= 3) {
      final query = val.toLowerCase();
      setState(() {
        _searchResults = _allCustomers
            .where((customer) {
              // కస్టమర్ పేరు లేదా ఫోన్ నంబర్ లో ఎక్కడ మ్యాచ్ అయినా పట్టుకుంటుంది
              return customer.name.toLowerCase().contains(query) ||
                  customer.phone.contains(query);
            })
            .take(10)
            .toList(); // టాప్ 10 రిజల్ట్స్ మాత్రమే
      });
    } else {
      setState(() => _searchResults = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PosProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NAME FIELD
          _buildTextField(
            controller: provider.nameController,
            hintText: 'Customer Name',
            icon: Icons.person_outline,
            onChanged: _onNameChanged,
          ),

          // 🟢 3. BEAUTIFUL INLINE SEARCH RESULT LIST
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final customer = _searchResults[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF1F3F6),
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.blueGrey,
                      ),
                    ),
                    title: Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      customer.phone,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      setState(() {
                        provider.nameController.text = customer.name;
                        provider.phoneController.text = customer.phone;
                        _searchResults = []; // సెలెక్ట్ చేసాక క్లోజ్ చేయడం
                      });
                      FocusScope.of(context).unfocus(); // కీబోర్డ్ హైడ్ చేయడం
                    },
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          // PHONE FIELD
          _buildTextField(
            controller: provider.phoneController,
            hintText: 'Phone',
            icon: Icons.phone_iphone_outlined,
            isPhone: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPhone = false,
    Function(String)? onChanged,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: Colors.blueGrey.shade400),
          filled: true,
          fillColor: const Color(0xFFF1F3F6),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFF5733), width: 1),
          ),
        ),
      ),
    );
  }
}
