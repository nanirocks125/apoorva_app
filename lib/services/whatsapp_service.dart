import 'dart:typed_data';
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/model/whatsapp_script.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

class WhatsAppService {
  final FirebaseFirestore _db;

  WhatsAppService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  Future<void> saveScript(String orgId, WhatsAppScript script) async {
    try {
      // 1. Create a reference to a NEW document (this doesn't save it yet)
      final docRef = _db
          .collection('organizations')
          .doc(orgId)
          .collection('scripts')
          .doc(); // No ID passed = Firestore generates one

      // 2. Update the script object with the newly generated ID
      final scriptWithId = script.copyWithId(docRef.id);

      // 3. Save the JSON (now containing the correct ID) to that specific reference
      await docRef.set(scriptWithId.toJson());
    } catch (e) {
      throw Exception('Failed to save script to Apoorva library: $e');
    }
  }

  // 1. Get Live Scripts Stream (Typed Models)
  Stream<List<WhatsAppScript>> getScriptsStream(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('scripts')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WhatsAppScript.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<Sale>> getUnsentSales(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('sales')
        .where('whatsappStatus', isEqualTo: 'unsent')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Sale.fromFirestore(doc),
              ) // Bridge వాడటం వల్ల ID కూడా వస్తుంది
              .toList(),
        );
  }

  // 2. Core Launch Logic
  // WhatsAppService లోపల:
  Future<void> launchWhatsApp({
    required String phone,
    required String message,
  }) async {
    final String messageEncoded = Uri.encodeComponent(message);
    final Uri appUrl = Uri.parse(
      "whatsapp://send?phone=$phone&text=$messageEncoded",
    );
    final Uri webUrl = Uri.parse("https://wa.me/$phone?text=$messageEncoded");

    try {
      // 🟢 లాంచ్ అయిందో లేదో వెరిఫై చేయండి
      final bool launched = await launchUrl(
        appUrl,
        mode: LaunchMode.externalApplication,
      );

      // ఒకవేళ లాంచ్ అవ్వకపోతే (false వస్తే), వెబ్ లింక్ ట్రై చేయండి
      if (!launched) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // ఎక్సెప్షన్ వచ్చినా వెబ్ లింక్ ట్రై చేయండి
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> sendInvoiceWithPDF({
    required String phone,
    required String message,
    required String saleId,
    required Uint8List pdfBytes,
  }) async {
    if (kIsWeb) {
      // --- WEB LOGIC ---
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "Apoorva_Invoice_$saleId.pdf")
        ..click();

      html.Url.revokeObjectUrl(url);

      final String encodedMsg = Uri.encodeComponent(message);
      final String whatsappUrl = "https://wa.me/$phone?text=$encodedMsg";
      html.window.open(whatsappUrl, '_blank');
    } else {
      // --- MOBILE LOGIC ---
      // We use 'dart:io' stuff only here.
      // The universal_html package ensures this file compiles for Android.
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Apoorva_Invoice_$saleId.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(file.path)], text: message);
    }
  }
}
