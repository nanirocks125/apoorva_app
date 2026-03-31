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
    required double subTotal,
    double totalSavings = 0.0,
    double roundOff = 0.0, // Added Round Off parameter
  }) async {
    final pdf = pw.Document();
    const double rollWidth = 48 * PdfPageFormat.mm;
    const divider = "- - - - - - - - - - - - - - - - - - - - - - -";

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          rollWidth,
          double.infinity,
          marginAll: 0,
        ),
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 3 * PdfPageFormat.mm,
              vertical: 5 * PdfPageFormat.mm,
            ),
            child: pw.Column(
              children: [
                // --- BRANDING ---
                pw.Text(
                  "APOORVA",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                pw.Text(
                  "1 Gram Jewellery & Fancy",
                  style: const pw.TextStyle(fontSize: 7),
                ),
                pw.Text(
                  "Mangalagiri, AP",
                  style: const pw.TextStyle(fontSize: 7),
                ),
                pw.SizedBox(height: 4),
                pw.Text(divider, style: const pw.TextStyle(fontSize: 7)),

                // --- METADATA ---
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Bill: ${saleId.substring(0, 8)}",
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                    pw.Text(
                      DateTime.now().toString().split(' ')[0],
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    "Cust: ${customerName.toUpperCase()}",
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Text(divider, style: const pw.TextStyle(fontSize: 7)),

                // --- ITEMS LIST ---
                pw.SizedBox(height: 2),
                ...items.map((item) {
                  final double itemDiscount =
                      item.stickerPrice - item.finalPrice;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 3),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item.categoryName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.RichText(
                                  text: pw.TextSpan(
                                    children: [
                                      pw.TextSpan(
                                        text: "MRP: Rs.",
                                        style: const pw.TextStyle(
                                          fontSize: 7,
                                          color: PdfColors.grey700,
                                        ),
                                      ),
                                      pw.TextSpan(
                                        text: item.stickerPrice.toStringAsFixed(
                                          0,
                                        ),
                                        style: pw.TextStyle(
                                          fontSize: 7,
                                          color: PdfColors.grey700,
                                          decoration:
                                              pw.TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (itemDiscount > 0)
                                  pw.Text(
                                    "Discount: -Rs.${itemDiscount.toStringAsFixed(0)}",
                                    style: const pw.TextStyle(
                                      fontSize: 7,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                              ],
                            ),
                            pw.Text(
                              "Rs.${item.finalPrice.toStringAsFixed(2)}",
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                pw.Text(divider, style: const pw.TextStyle(fontSize: 7)),

                // --- FINAL SUMMARY SECTION ---

                // 1. Grand Total (Before Rounding)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "GRAND TOTAL",
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                    pw.Text(
                      "Rs.${subTotal.toStringAsFixed(2)}",
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),

                // 1. Round Off Row (Only shows if there is a value)
                if (roundOff != 0)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "Additional Discount",
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          "${roundOff > 0 ? '-' : ''}${roundOff.toStringAsFixed(2)}",
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),

                // 2. Net Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "NET TOTAL",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "Rs.$netPayable",
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                // 3. Savings Box
                if (totalSavings > 0)
                  pw.Container(
                    width: double.infinity,
                    margin: const pw.EdgeInsets.only(top: 6),
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.8),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(1),
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          "CONGRATULATIONS!",
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          "YOU SAVED Rs.${totalSavings.toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                pw.SizedBox(height: 10),

                // --- QR & FOOTER ---
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: "https://www.instagram.com/apoorva.online/",
                  width: 48,
                  height: 48,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  "Scan to follow @apoorva.online",
                  style: const pw.TextStyle(fontSize: 6.5),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  "Thank You! Visit Again",
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
