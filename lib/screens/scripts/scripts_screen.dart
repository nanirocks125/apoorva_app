import 'package:apoorva_app/screens/scripts/create_script_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ScriptsScreen extends StatelessWidget {
  final String orgId;

  const ScriptsScreen({super.key, required this.orgId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caption & Script Library'), // PRD
        backgroundColor: const Color(0xFF25D366), // WhatsApp Green
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .collection('scripts')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final scripts = snapshot.data?.docs ?? [];
          if (scripts.isEmpty) {
            return const Center(
              child: Text('No scripts found. Add some in Admin mode!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scripts.length,
            itemBuilder: (context, index) {
              final data = scripts[index].data() as Map<String, dynamic>;
              return _buildScriptCard(context, data);
            },
          );
        },
      ),
      // Admin-only toggle could be added here later [cite: 36]
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScriptDialog(context),
        backgroundColor: const Color(0xFFFF5733),
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildScriptCard(BuildContext context, Map<String, dynamic> data) {
    final String content = data['content'] ?? '';
    final String language = data['language'] ?? 'English';

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
                Text(
                  data['title'] ?? 'Untitled Script',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(language, style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.orange.shade50,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(color: Colors.grey.shade800, height: 1.4),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
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
                  onPressed: () => _launchWhatsApp(content),
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

  Future<void> _launchWhatsApp(String text) async {
    final url = "whatsapp://send?text=${Uri.encodeComponent(text)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // A simple dialog to add new scripts manually
  void _showScriptDialog(BuildContext context) {
    // Implement standard Add Script dialog here
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateScriptScreen(orgId: orgId)),
    );
  }
}
