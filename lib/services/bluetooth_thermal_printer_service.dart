import 'dart:typed_data';

import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/services/pdf_invoice_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class BluetoothThermalPrinterService {
  late BlueThermalPrinter _bluetooth;

  BluetoothThermalPrinterService({BlueThermalPrinter? bluetooth}) {
    _bluetooth = bluetooth ?? BlueThermalPrinter.instance;
  }
  void printReceiptViaBluetooth(BuildContext context, Sale sale) async {
    try {
      // 1. Check if Bluetooth is even on
      bool? isConnected = await _bluetooth.isConnected;

      // 2. Get list of paired (bonded) devices
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();

      // 3. Find the Seznik printer in the list
      // Thermal printers often show up as 'MPT-II', 'Seznik', or 'Bluetooth Printer'
      BluetoothDevice? seznik = devices.firstWhere(
        (d) =>
            d.name!.toLowerCase().contains("seznik") ||
            d.name!.toLowerCase().contains("mpt") ||
            d.name!.toLowerCase().contains("printer"),
        orElse: () => throw Exception(
          "Seznik Printer not found. Please pair it in Android Bluetooth settings first.",
        ),
      );

      // 4. Connect if not already connected
      if (!isConnected!) {
        await _bluetooth.connect(seznik);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Printing Receipt...")));

      // 5. Generate the 48mm bytes
      final Uint8List pdfBytes = await PdfInvoiceService.generate48mmReceipt(
        customerName: sale.customerName,
        netPayable: sale.netPayable.toStringAsFixed(2),
        saleId: sale.id,
        items: sale.items,
        subTotal: sale.subtotal, // Pass subtotal for accurate receipt
        totalSavings: sale.totalSavings, // Calculate total savings
        roundOff: sale.roundOff, // Pass round-off if needed
      );

      // 6. Rasterize PDF to Image
      // Thermal printers print dots, so we convert the PDF page to a PNG image
      await for (var page in Printing.raster(pdfBytes, pages: [0], dpi: 200)) {
        final imageBytes = await page.toPng();

        // 7. Send to Printer
        await _bluetooth.printImageBytes(imageBytes);

        // Feed paper so it can be torn off
        _feedPaper();
      }
    } catch (e) {
      print('bluetooth error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bluetooth Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      // throw Exception("Seznik Printer not found. Please pair it first.");
      rethrow;
    }
  }

  void _feedPaper() {
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
  }
}
