import 'package:apoorva_app/model/sale.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ReceiptCommunicationService {
  Future<void> sendWhatsAppTextOnly(BuildContext context, Sale sale) async {
    if (sale.customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not provided!')),
      );
      return;
    }

    String itemsList = sale.items
        .asMap()
        .entries
        .map((entry) {
          var item = entry.value;
          return "${entry.key + 1}. *${item.categoryName.toUpperCase()}*\n"
              "   MRP: ~Rs ${item.stickerPrice.toStringAsFixed(0)}~ → *Rs ${item.finalPrice.toStringAsFixed(2)}*";
        })
        .join("\n\n");

    final String message =
        "✨ *APOORVA JEWELLERY* ✨\n"
        "Hello ${sale.customerName},\n"
        "Your digital bill is ready. 🙏\n\n"
        "📦 *ITEMS:* \n$itemsList\n\n"
        "💰 *NET PAYABLE: Rs ${sale.netPayable.toStringAsFixed(2)}*\n"
        "✨ *YOU SAVED Rs ${sale.totalSavings.toStringAsFixed(2)}!* ✨\n\n"
        "Bill ID: ${sale.id.substring(0, 8)}\n"
        "Visit Again! 🙏";

    String phone = sale.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length == 10) phone = "91$phone";

    final Uri url = Uri.parse(
      "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}",
    );
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void sendTextMessage(BuildContext context, Sale sale) async {
    // 1. Build a multi-line, detailed Item List
    String itemsList = sale.items
        .asMap()
        .entries
        .map((entry) {
          int idx = entry.key + 1;
          var item = entry.value;
          double itemDiscount = item.stickerPrice - item.finalPrice;

          return "$idx. ${item.categoryName.toUpperCase()}\n"
              "   MRP: Rs ${item.stickerPrice.toStringAsFixed(0)}\n"
              "   Discount: Rs ${itemDiscount.toStringAsFixed(0)}\n"
              "   Final Price: Rs ${item.finalPrice.toStringAsFixed(2)}";
        })
        .join("\n\n");

    // 2. Summary Section
    String summarySection = "Subtotal: Rs ${sale.subtotal.toStringAsFixed(2)}";
    if (sale.roundOff != 0) {
      summarySection +=
          "\nExtra Disc: -Rs ${sale.roundOff.abs().toStringAsFixed(2)}";
    }
    summarySection += "\nNet Payable: Rs ${sale.netPayable.toStringAsFixed(2)}";

    // 3. Savings Message
    String savingsMessage = "";
    if (sale.totalSavings > 0) {
      savingsMessage =
          "---------------------------\n"
          "YOU SAVED Rs ${sale.totalSavings.toStringAsFixed(2)}! \n"
          "---------------------------";
    }

    // 4. Final Message Assembly
    final String message =
        "APOORVA JEWELLERY\n"
        "Mangalagiri, AP\n\n"
        "Hello ${sale.customerName},\n"
        "Digital Bill for your purchase:\n\n"
        "ITEMS:\n"
        "$itemsList\n\n"
        "BILL SUMMARY:\n"
        "$summarySection\n\n"
        "$savingsMessage\n\n"
        "Bill ID: ${sale.id.substring(0, 8)}\n"
        "Visit Again! 🙏";

    // 5. Phone Formatting
    String phone = sale.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length == 10) phone = "91$phone";

    // Launch standard SMS directly
    final Uri smsUrl = Uri.parse(
      "sms:$phone?body=${Uri.encodeComponent(message)}",
    );

    try {
      if (await canLaunchUrl(smsUrl)) {
        await launchUrl(smsUrl);
      } else {
        // ఇక్కడ else బ్లాక్ తప్పనిసరి!
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not open SMS app")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open SMS app")));
    }
  }
}
