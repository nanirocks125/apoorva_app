import 'dart:typed_data';

import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/services/pdf_invoice_service.dart';
import 'package:apoorva_app/services/whatsapp_service.dart';
import 'package:flutter/material.dart';

class InvoiceDocumentSharingService {
  final WhatsAppService _whatsAppService;

  InvoiceDocumentSharingService({WhatsAppService? whatsAppService})
    : _whatsAppService = whatsAppService ?? WhatsAppService();
  void sendInvoiceDocument(
    BuildContext context,
    Sale sale,
    String saleId,
  ) async {
    try {
      // 1. Show a loading indicator (Good for UX)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Generating Invoice PDF...")),
      );

      // 2. Generate the PDF Bytes using your Service
      final Uint8List pdfBytes = await PdfInvoiceService.generateInvoiceBytes(
        customerName: sale.customerName,
        netPayable: sale.netPayable.toStringAsFixed(2),
        saleId: saleId,
        items: sale.items,
        subTotal: sale.subtotal,
        totalSavings: sale.totalSavings,
        roundOff: sale.roundOff, // This is your List<SaleItem>
      );

      // 3. Define your WhatsApp Message (Pull from your Scripts if you have them)
      final String whatsappMessage =
          "Hello ${sale.customerName}! Thank you for shopping at Apoorva Jewelry. 🙏 "
          "Attached is your invoice for Bill ID: ${saleId.substring(0, 8)}. "
          "We hope to see you again in Mangalagiri soon!";

      // 4. Call your WhatsApp Service to trigger the Share Sheet
      await _whatsAppService.sendInvoiceDirectToWhatsapp(
        phone: sale.customerPhone,
        message: whatsappMessage,
        saleId: saleId,
        pdfBytes: pdfBytes,
      );
    } catch (e) {
      // Handle any errors (like if the user cancels or the file system fails)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }
}
