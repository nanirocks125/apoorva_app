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

  static Future<Uint8List> generate48mmReceipt({
    required String customerName,
    required String netPayable,
    required String saleId,
    required List<SaleItem> items,
  }) async {
    final pdf = pw.Document();

    // 48mm converted to points
    const double rollWidth = 48 * PdfPageFormat.mm;

    pdf.addPage(
      pw.Page(
        // 1. Set margins to 0 so the white background covers the entire roll width
        pageFormat: const PdfPageFormat(
          rollWidth,
          double.infinity,
          marginAll: 0,
        ),
        build: (pw.Context context) {
          // 2. Wrap EVERYTHING in a white Container
          return pw.Container(
            color: PdfColors.white,
            // 3. Move the padding here instead of page margins
            padding: const pw.EdgeInsets.all(2 * PdfPageFormat.mm),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Branding Header
                pw.Center(
                  child: pw.Text(
                    "APOORVA",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black, // Explicitly set black text
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    "Mangalagiri",
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.black,
                    ),
                  ),
                ),
                pw.Divider(thickness: 0.5, color: PdfColors.black),

                // Bill Details
                pw.Text(
                  "Bill: ${saleId.substring(0, 6)}",
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.black,
                  ),
                ),
                pw.Text(
                  "Date: ${DateTime.now().toString().split(' ')[0]}",
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.black,
                  ),
                ),
                pw.Text(
                  "Cust: $customerName",
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 5),

                // Items list
                pw.Divider(thickness: 0.2, color: PdfColors.black),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        "Item",
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Text(
                      "Price",
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.2, color: PdfColors.black),

                ...items.map(
                  (item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            item.categoryName,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Text(
                          item.finalPrice.toString(),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ),

                pw.Divider(thickness: 0.5, color: PdfColors.black),

                // Total Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "TOTAL:",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "Rs. $netPayable",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    "Thank You! Visit Again",
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.SizedBox(height: 30), // Space for tearing
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
