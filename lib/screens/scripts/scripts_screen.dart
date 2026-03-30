import 'package:apoorva_app/model/whatsapp_script.dart';
import 'package:apoorva_app/services/whatsapp_service.dart';
import 'package:apoorva_app/screens/scripts/create_script_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScriptsScreen extends StatelessWidget {
  final String orgId;

  const ScriptsScreen({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caption & Script Library'),
        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
      ),
      body: StreamBuilder<List<WhatsAppScript>>(
        // 1. Using our typed Service Stream
        stream: WhatsAppService().getScriptsStream(orgId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final scripts = snapshot.data ?? [];
          if (scripts.isEmpty) {
            return const Center(
              child: Text('No scripts found. Add some in Admin mode!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scripts.length,
            itemBuilder: (context, index) {
              final script = scripts[index]; // Now a typed Model!
              return _buildScriptCard(context, script);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScriptDialog(context),
        backgroundColor: const Color(0xFFFF5733),
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildScriptCard(BuildContext context, WhatsAppScript script) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    script.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    script.language,
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.orange.shade50,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              script.content,
              style: TextStyle(color: Colors.grey.shade800, height: 1.4),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: script.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Script copied to clipboard!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 20),
                  label: const Text('COPY'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                  ),
                  // 2. Using our Service Launch Logic
                  onPressed: () => WhatsAppService().launchWhatsApp(
                    phone: '', // General share, no specific phone here
                    message: script.content,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text('SHARE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showScriptDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateScriptScreen(orgId: orgId)),
    );
  }
}
