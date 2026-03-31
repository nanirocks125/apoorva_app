import 'dart:typed_data';
import 'package:apoorva_app/model/sale_item.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfInvoiceService {
  static Future<void> createAndShareInvoice({
    required String customerName,
    required String netPayable,
    required String saleId,
    required List<SaleItem> items, // Your cart items
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header: Apoorva Branding
              pw.Center(
                child: pw.Text(
                  "APOORVA JEWELLERY",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(child: pw.Text("Mangalagiri, Andhra Pradesh")),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // 2. Customer Info
              pw.Text("Bill ID: ${saleId.substring(0, 8)}"),
              pw.Text("Date: ${DateTime.now().toString().split(' ')[0]}"),
              pw.Text("Customer: $customerName"),
              pw.SizedBox(height: 20),

              // 3. Items Table
              pw.TableHelper.fromTextArray(
                headers: ['Item', 'Price'],
                data: items
                    .map(
                      (item) => [item.categoryName, "Rs. ${item.finalPrice}"],
                    )
                    .toList(),
              ),

              pw.Divider(),
              // 4. Totals
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Total Payable: Rs. $netPayable",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 40),

              // 5. Mandatory Care Instructions (From PRD)
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                ),
                child: pw.Text(
                  "CARE INSTRUCTIONS: Keep your jewelry away from water, perfumes, and chemicals to maintain its shine. Store in an airtight pouch after use.",
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    print('laying out pdf');

    // 6. Preview & Share (This opens the native Print/Share dialog)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Apoorva_Bill_${saleId.substring(0, 4)}.pdf',
    );
  }

  // Inside PdfInvoiceService class
  static Future<Uint8List> generateInvoiceBytes({
    required String customerName,
    required String netPayable,
    required String saleId,
    required List<SaleItem> items,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          // ... (Keep all your existing pw.Column code here) ...
          return pw.Column(children: [/* your existing code */]);
        },
      ),
    );

    return pdf.save(); // Return the bytes instead of calling layoutPdf
  }
}
