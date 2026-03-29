import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateScriptScreen extends StatefulWidget {
  final String orgId;

  const CreateScriptScreen({super.key, required this.orgId});

  @override
  State<CreateScriptScreen> createState() => _CreateScriptScreenState();
}

class _CreateScriptScreenState extends State<CreateScriptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedLanguage = 'Telugu'; // Default for Mangalagiri
  bool _isSaving = false;

  Future<void> _saveScript() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.orgId)
          .collection('scripts')
          .add({
            'title': _titleController.text.trim(),
            'content': _contentController.text.trim(),
            'language': _selectedLanguage,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Script added to library! ✨'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Sales Script')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Language Toggle
            const Text(
              'Language',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Telugu', label: Text('Telugu')),
                ButtonSegment(value: 'English', label: Text('English')),
              ],
              selected: {_selectedLanguage},
              onSelectionChanged: (set) =>
                  setState(() => _selectedLanguage = set.first),
            ),
            const SizedBox(height: 24),

            // 2. Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Script Title (e.g., Diwali Greeting)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),

            // 3. Content Field
            TextFormField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Message Content',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                helperText: 'Use [NAME], [AMOUNT], or [ID] as placeholders.',
              ),
              validator: (v) => v!.isEmpty ? 'Content is required' : null,
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: const Color(0xFFFF5733),
              ),
              onPressed: _isSaving ? null : _saveScript,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'SAVE TO LIBRARY',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
