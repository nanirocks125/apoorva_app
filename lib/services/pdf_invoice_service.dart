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
    required double subTotal,
    double totalSavings = 0.0,
    double roundOff = 0.0,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(1 * PdfPageFormat.cm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- HEADER SECTION ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "APOORVA",
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.Text(
                        "1 Gram Jewellery & Fancy",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        "Mangalagiri, Andhra Pradesh",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "INVOICE",
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        "Bill ID: $saleId",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        "Date: ${DateTime.now().toString().split(' ')[0]}",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // --- CUSTOMER INFO ---
              pw.Text(
                "BILL TO:",
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                customerName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // --- ITEMS TABLE ---
              pw.Table(
                border: pw.TableBorder.symmetric(
                  inside: const pw.BorderSide(
                    width: 0.5,
                    color: PdfColors.grey300,
                  ),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40), // S.No
                  1: const pw.FlexColumnWidth(3), // Item Description
                  2: const pw.FlexColumnWidth(1), // MRP
                  3: const pw.FlexColumnWidth(1), // Discount
                  4: const pw.FlexColumnWidth(1), // Final Amount
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _tableHeader("#"),
                      _tableHeader("Item Description"),
                      _tableHeader("MRP"),
                      _tableHeader("Discount"),
                      _tableHeader("Amount"),
                    ],
                  ),
                  // Table Data
                  ...items.asMap().entries.map((entry) {
                    int index = entry.key;
                    var item = entry.value;
                    double discount = item.stickerPrice - item.finalPrice;

                    return pw.TableRow(
                      children: [
                        _tableCell((index + 1).toString()),
                        _tableCell(item.categoryName.toUpperCase()),
                        // MRP with Scratch
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.RichText(
                            textAlign: pw.TextAlign.right,
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: "Rs.",
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                                pw.TextSpan(
                                  text: item.stickerPrice.toStringAsFixed(0),
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    decoration: pw.TextDecoration.lineThrough,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _tableCell(
                          discount > 0
                              ? "-Rs.${discount.toStringAsFixed(0)}"
                              : "-",
                          align: pw.TextAlign.right,
                        ),
                        _tableCell(
                          "Rs.${item.finalPrice.toStringAsFixed(2)}",
                          align: pw.TextAlign.right,
                          isBold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 10),

              // --- SUMMARY SECTION ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Social Media / QR Section on Left
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: "https://www.instagram.com/apoorva.online/",
                        width: 60,
                        height: 60,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        "Scan to follow @apoorva.online",
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                  // Totals Section on Right
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        _summaryRow(
                          "GRAND TOTAL",
                          "Rs.${subTotal.toStringAsFixed(2)}",
                        ),
                        if (roundOff != 0)
                          _summaryRow(
                            "ADDITIONAL DISCOUNT",
                            "${roundOff > 0 ? '-' : ''}${roundOff.toStringAsFixed(2)}",
                          ),
                        pw.Divider(),
                        _summaryRow(
                          "NET PAYABLE",
                          "Rs.$netPayable",
                          isTotal: true,
                        ),

                        // Savings Box
                        if (totalSavings > 0)
                          pw.Container(
                            margin: const pw.EdgeInsets.only(top: 10),
                            padding: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: PdfColors.black,
                                width: 1,
                              ),
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4),
                              ),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text(
                                  "CONGRATULATIONS!",
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  "YOU SAVED Rs.${totalSavings.toStringAsFixed(2)}",
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),
              // Footer
              pw.Center(
                child: pw.Text(
                  "Thank You for shopping at Apoorva! Visit Again.",
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

    return pdf.save();
  }

  // --- HELPER WIDGETS FOR A4 TABLE ---

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 12 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 10,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
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
