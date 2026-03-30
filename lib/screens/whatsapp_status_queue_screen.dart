import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/model/whatsapp_script.dart';
import 'package:flutter/material.dart';
import 'package:apoorva_app/services/whatsapp_service.dart';
import 'package:apoorva_app/services/sale_service.dart'; // assuming markAsSent is here

class WhatsappQueueScreen extends StatelessWidget {
  final String orgId;

  const WhatsappQueueScreen({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unsent Bills Queue'),
        backgroundColor: const Color(0xFF25D366),
      ),
      body: StreamBuilder<List<Sale>>(
        // 1. Using Typed Stream from Service
        stream: WhatsAppService().getUnsentSales(orgId),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sales = snapshot.data ?? [];
          if (sales.isEmpty) {
            return const Center(child: Text('All bills are synced! 🎉'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  title: Text(
                    '${sale.customerName} - ₹${sale.netPayable.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('ID: ${sale.id.substring(0, 8)}...'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.green,
                        ),
                        onPressed: () => _openScriptLibrary(context, sale),
                        tooltip: 'Select Script and Share',
                      ),
                      const VerticalDivider(),
                      TextButton(
                        onPressed: () => _handleMarkAsSent(context, sale.id),
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

  void _openScriptLibrary(BuildContext context, Sale sale) {
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
              child: StreamBuilder<List<WhatsAppScript>>(
                // 2. Using Typed Scripts Stream
                stream: WhatsAppService().getScriptsStream(orgId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final scripts = snapshot.data ?? [];

                  if (scripts.isEmpty)
                    return const Center(child: Text('No scripts available.'));

                  return ListView.builder(
                    itemCount: scripts.length,
                    itemBuilder: (context, idx) {
                      final script = scripts[idx];
                      return ListTile(
                        title: Text(script.title),
                        subtitle: Text(script.language),
                        trailing: const Icon(Icons.send, color: Colors.green),
                        onTap: () {
                          Navigator.pop(context);
                          _processWhatsAppShare(
                            context: context,
                            sale: sale,
                            script: script,
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
    required Sale sale,
    required WhatsAppScript script,
  }) async {
    // 3. Centralized Formatting logic from the model
    final String message = script.formatMessage(sale);

    try {
      await WhatsAppService().launchWhatsApp(
        phone: sale.customerPhone,
        message: message,
      );

      if (context.mounted) {
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
          await _handleMarkAsSent(context, sale.id);
        }
      }
    } catch (e) {
      debugPrint("WhatsApp Launch Error: $e");
    }
  }

  Future<void> _handleMarkAsSent(BuildContext context, String saleId) async {
    // Reconciling digital record with physical activity
    await SaleService().markSaleAsSent(orgId: orgId, saleId: saleId);

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
