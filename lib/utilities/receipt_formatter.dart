import 'package:url_launcher/url_launcher.dart';
import 'package:apoorva_app/model/sale.dart';

class ReceiptFormatter {
  static String formatSaleAsText(Sale sale) {
    final itemsBuffer = StringBuffer();
    for (var i = 0; i < sale.items.length; i++) {
      final item = sale.items[i];
      itemsBuffer.writeln("${i + 1}. *${item.categoryName.toUpperCase()}*");
      itemsBuffer.writeln(
        "   MRP: ~Rs ${item.stickerPrice}~ → *Rs ${item.finalPrice}*",
      );
    }

    return """
✨ *APOORVA JEWELLERY* ✨
Hello ${sale.customerName},
Digital bill for ID: ${sale.id.substring(0, 8)}

📦 *ITEMS:*
$itemsBuffer

💰 *TOTAL: Rs ${sale.netPayable}*
🥳 *SAVINGS: Rs ${sale.totalSavings}*

Visit Again! 🙏
""";
  }

  static Future<void> sendWhatsApp(Sale sale) async {
    final message = formatSaleAsText(sale);
    final phone = _formatPhone(sale.customerPhone);
    final url = Uri.parse(
      "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}",
    );
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  static String _formatPhone(String phone) {
    String p = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return p.length == 10 ? "91$p" : p;
  }
}
