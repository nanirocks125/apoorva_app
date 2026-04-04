import 'dart:typed_data';

import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/services/pdf_invoice_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

typedef ReceiptGenerator = Future<Uint8List> Function(Sale sale);

class PrinterWrapper {
  Future<Uint8List> generateReceipt(Sale sale) {
    return PdfInvoiceService.generate48mmReceipt(
      customerName: sale.customerName,
      netPayable: sale.netPayable.toStringAsFixed(2),
      saleId: sale.id,
      items: sale.items,
      subTotal: sale.subtotal,
      totalSavings: sale.totalSavings,
      roundOff: sale.roundOff,
    );
  }

  Stream<PdfRaster> rasterize(Uint8List pdfBytes) {
    return Printing.raster(pdfBytes, pages: [0], dpi: 200);
  }
}

class BluetoothThermalPrinterService {
  final BlueThermalPrinter _bluetooth;
  final PrinterWrapper _wrapper;

  // Use 'wrapper' instead of 'generator' here
  BluetoothThermalPrinterService({
    BlueThermalPrinter? bluetooth,
    PrinterWrapper? wrapper,
  }) : _bluetooth = bluetooth ?? BlueThermalPrinter.instance,
       _wrapper = wrapper ?? PrinterWrapper();

  Future<void> printReceiptViaBluetooth(BuildContext context, Sale sale) async {
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
      final Uint8List pdfBytes = await _wrapper.generateReceipt(sale);

      // 6. Rasterize PDF to Image
      // Thermal printers print dots, so we convert the PDF page to a PNG image
      await for (var page in _wrapper.rasterize(pdfBytes)) {
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
