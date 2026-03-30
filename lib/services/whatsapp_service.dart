import 'package:apoorva_app/model/whatsapp_script.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WhatsAppService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Get Live Scripts Stream (Typed Models)
  Stream<List<WhatsAppScript>> getScriptsStream(String orgId) {
    return _db
        .collection('organizations')
        .doc(orgId)
        .collection('scripts')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WhatsAppScript.fromFirestore(doc))
              .toList(),
        );
  }

  // 2. Core Launch Logic
  Future<void> launchWhatsApp({
    required String phone,
    required String message,
  }) async {
    Uri url;
    if (kIsWeb) {
      url = Uri.parse(
        "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
      );
    } else {
      url = Uri.parse(
        "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}",
      );
    }

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Fallback for mobile if whatsapp:// fails
      if (!kIsWeb) {
        final fallbackUrl = Uri.parse(
          "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
        );
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    }
  }
}
