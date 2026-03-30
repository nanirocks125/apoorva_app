import 'package:apoorva_app/model/sale.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'whatsapp_script.g.dart';

@JsonSerializable(explicitToJson: true)
class WhatsAppScript {
  final String id;
  final String title;
  final String content;
  final String language; // 'Telugu', 'English', 'Tanglish'
  final bool isActive;

  WhatsAppScript({
    required this.id,
    required this.title,
    required this.content,
    required this.language,
    this.isActive = true,
  });

  // --- JSON Logic ---
  factory WhatsAppScript.fromJson(Map<String, dynamic> json) =>
      _$WhatsAppScriptFromJson(json);
  Map<String, dynamic> toJson() => _$WhatsAppScriptToJson(this);

  // --- Firestore Bridge ---
  factory WhatsAppScript.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WhatsAppScript.fromJson(data).copyWithId(doc.id);
  }

  WhatsAppScript copyWithId(String newId) => WhatsAppScript(
    id: newId,
    title: title,
    content: content,
    language: language,
    isActive: isActive,
  );

  // --- Helper: Placeholder Processor ---
  // మంగళగిరి షాపులో కస్టమర్ పేరు, అమౌంట్ ని ఆటోమేటిక్ గా మెసేజ్ లో మారుస్తుంది
  String formatMessage(Sale sale) {
    String formatted = content
        .replaceAll('[NAME]', sale.customerName)
        .replaceAll('[AMOUNT]', sale.netPayable.toStringAsFixed(2))
        .replaceAll('[ID]', sale.id);

    // జ్యువెలరీ కేర్ టిప్ ని ఆటోమేటిక్ గా చివరన యాడ్ చేస్తుంది
    return "$formatted\n\n✨ Care Tip: Keep your jewelry away from perfumes and water to maintain its high-res shine!";
  }
}
