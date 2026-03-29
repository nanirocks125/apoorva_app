import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsappQueueScreen extends StatelessWidget {
  final String orgId; // Foundation for multi-tenancy

  const WhatsappQueueScreen({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unsent Bills Queue'),
        backgroundColor: const Color(0xFF25D366), // WhatsApp Brand Color
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Only fetch sales marked as 'unsent' to maintain Cash Integrity [cite: 9, 43]
        stream: FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('sales')
            .where('whatsapp_status', isEqualTo: 'unsent')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sales = snapshot.data!.docs;
          if (sales.isEmpty) {
            return const Center(child: Text('All bills are synced! 🎉'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final saleDoc = sales[index];
              final sale = saleDoc.data() as Map<String, dynamic>;
              final String saleId = saleDoc.id;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  title: Text(
                    '${sale['customerName']} - ₹${sale['netPayable']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('ID: ${saleId.substring(0, 8)}...'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // STEP 1: Select Script & Share [cite: 36, 40]
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.green,
                        ),
                        onPressed: () =>
                            _openScriptLibrary(context, saleId, sale),
                        tooltip: 'Select Script and Share',
                      ),
                      const VerticalDivider(),
                      // STEP 2: Manual Override [cite: 43]
                      TextButton(
                        onPressed: () => _markAsSent(context, saleId),
                        child: const Text(
                          'MARK SENT',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Opens the Caption & Script Library bottom sheet
  void _openScriptLibrary(
    BuildContext context,
    String saleId,
    Map<String, dynamic> saleData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            const Text(
              'Select Message Script',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Fetch organization-specific scripts
                stream: FirebaseFirestore.instance
                    .collection('organizations')
                    .doc(orgId)
                    .collection('scripts')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final scripts = snapshot.data!.docs;

                  if (scripts.isEmpty)
                    return const Center(child: Text('No scripts available.'));

                  return ListView.builder(
                    itemCount: scripts.length,
                    itemBuilder: (context, idx) {
                      final script =
                          scripts[idx].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(script['title'] ?? 'Untitled'),
                        subtitle: Text(script['language'] ?? 'English'),
                        trailing: const Icon(Icons.send, color: Colors.green),
                        onTap: () {
                          Navigator.pop(context); // Close sheet
                          _processWhatsAppShare(
                            context: context,
                            orgId: orgId,
                            saleId: saleId,
                            phone: saleData['customerPhone'] ?? '',
                            template: script['content'] ?? '',
                            saleData: saleData,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processWhatsAppShare({
    required BuildContext context,
    required String orgId,
    required String saleId,
    required String phone,
    required String template,
    required Map<String, dynamic> saleData,
  }) async {
    // 1. Placeholder Replacement
    String message = template
        .replaceAll('[NAME]', saleData['customerName'] ?? 'Customer')
        .replaceAll('[AMOUNT]', '₹${saleData['netPayable']}')
        .replaceAll('[ID]', saleId);

    // 2. Add Mandatory Care Instructions [cite: 43, 44]
    message +=
        "\n\n✨ Care Tip: Keep jewelry away from perfumes and water to maintain shine!";

    // 3. Platform-Specific URI [cite: 58]
    final Uri url = kIsWeb
        ? Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}")
        : Uri.parse(
            "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}",
          );

    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (launched && context.mounted) {
        // 4. Manual Confirmation Dialog to ensure Zero Discrepancy [cite: 22, 37]
        final bool? isSent = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Sent'),
            content: const Text('Did you hit "Send" in WhatsApp?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('NO', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('YES, MARK SENT'),
              ),
            ],
          ),
        );

        if (isSent == true) {
          await _markAsSent(context, saleId);
        }
      }
    } catch (e) {
      debugPrint("Launch Error: $e");
    }
  }

  Future<void> _markAsSent(BuildContext context, String saleId) async {
    // Core POS logic: reconcile digital record with physical activity [cite: 9, 36, 43]
    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        .doc(saleId)
        .update({
          'whatsapp_status': 'sent',
          'last_shared_at': FieldValue.serverTimestamp(),
        });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale marked as SENT! ✨'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
