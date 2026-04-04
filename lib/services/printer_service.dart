import 'dart:typed_data';

import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/services/pdf_invoice_service.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PrinterService {
  void printReceipt(BuildContext context, Sale sale) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Connecting to Printer...")));

      // 1. Generate the narrow 48mm PDF bytes
      final Uint8List receiptBytes =
          await PdfInvoiceService.generateInvoiceBytes(
            customerName: sale.customerName,
            netPayable: sale.netPayable.toStringAsFixed(2),
            saleId: sale.id,
            items: sale.items,
            subTotal: sale.subtotal, // Pass subtotal for accurate receipt
            totalSavings: sale.totalSavings, // Calculate total savings
            roundOff: sale.roundOff, // Pass round-off if needed
          );

      // 2. Send directly to the paired Bluetooth printer
      // This will open the system print spooler optimized for the Seznik
      await Printing.layoutPdf(
        onLayout: (format) async => receiptBytes,
        name:
            'Apoorva_Receipt_${sale.id.length >= 4 ? sale.id.substring(0, 4) : sale.id}',
        dynamicLayout: true, // Crucial for roll-fed thermal printers
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Printing Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
