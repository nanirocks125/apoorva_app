import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomerDataHeader extends StatelessWidget {
  const CustomerDataHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PosProvider>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color:
          Colors.white, // వైట్ బ్యాక్‌గ్రౌండ్ ఉంచితే ఫీల్డ్స్ బాగా కనిపిస్తాయి
      child: Column(
        children: [
          _buildTextField(
            controller: provider.nameController,
            hintText: 'Customer Name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
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

  // రిపీటెడ్ కోడ్ తగ్గించడానికి హెల్పర్ మెథడ్
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPhone = false,
  }) {
    return SizedBox(
      height: 42, // కొంచెం హైట్ పెంచితే నీట్ గా ఉంటుంది
      child: TextField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: Colors.blueGrey.shade400),
          filled: true,
          fillColor: const Color(0xFFF1F3F6), // కొంచెం స్పష్టంగా కనిపించే గ్రే
          isDense: true, // హైట్ అడ్జస్ట్మెంట్ కి ఇది ముఖ్యం
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
