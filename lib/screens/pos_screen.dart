import 'package:apoorva_app/services/organization_service.dart';
import 'package:flutter/material.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key, required this.orgId});
  final String orgId;

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  // PRD ప్రకారం కేటగిరీల జాబితా [cite: 8, 31]
  // final List<String> categories = [
  //   'Bangles',
  //   'Panchaloha',
  //   'Necklace',
  //   'Earrings',
  //   'Sets',
  // ];

  OrganizationService get _orgService => OrganizationService();

  void _openSmartCalculator(String category) {
    // ఇక్కడ స్టిక్కర్ ధర మరియు 5%, 10% డిస్కౌంట్ బటన్లతో
    // క్యాలిక్యులేటర్ ఓపెన్ అవుతుంది.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apoorva POS')),
      body: Column(
        children: [
          // --- VISUAL DASHBOARD ---
          // PosScreen build method లోపల
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _orgService.getLiveCategories(widget.orgId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data ?? [];

                if (categories.isEmpty) {
                  return const Center(
                    child: Text('No categories found. Add some in Inventory!'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return _buildCategoryCard(
                      context,
                      cat['name'],
                      cat['current_stock'].toString(),
                      cat['is_hotkey'] ?? false,
                      cat['social_media_link'],
                      () => {},
                      // () => _openSmartCalculator(
                      //   cat,
                      // ), // బల్క్ కేటగిరీ లెవెల్ ట్రాకింగ్ [cite: 8]
                    );
                  },
                );
              },
            ),
          ),

          // --- CART & CHECKOUT ---
          _buildCartSummary(),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String name,
    String stock,
    bool isHotkey,
    String? socialLink,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHotkey ? const Color(0xFFFF5733) : Colors.grey.shade200,
            width: isHotkey ? 2 : 1, // హాట్-కీ అయితే హైలైట్ అవుతుంది
          ),
        ),
        child: Stack(
          children: [
            // Social Media Link Icon
            // if (socialLink != null && socialLink.isNotEmpty)
            //   Positioned(
            //     top: 8,
            //     right: 8,
            //     child: IconButton(
            //       icon: const Icon(
            //         Icons.instagram,
            //         color: Colors.pink,
            //         size: 20,
            //       ),
            //       onPressed: () =>
            //           _launchURL(socialLink), // Social Media Link Mapper
            //     ),
            //   ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: $stock',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String label) {
    return InkWell(
      onTap: () => _openSmartCalculator(label),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Items: 2'), Text('Total: ₹2,450')],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.green,
            ),
            onPressed: () {
              /* Tender Splitting Screen కి నావిగేట్ చేయండి  */
            },
            child: const Text(
              'CHECKOUT',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
