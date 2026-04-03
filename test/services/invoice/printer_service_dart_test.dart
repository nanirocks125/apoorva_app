import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdf/pdf.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart'; // IMPORTANT: For PrintingPlatform mocking

// Project Imports
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/services/printer_service.dart';

// Mocks
class MockPrintingPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PrintingPlatform {}

class MockSale extends Mock implements Sale {}

void main() {
  late PrinterService service;
  late MockPrintingPlatform mockPrintingPlatform;
  late MockSale mockSale;

  setUpAll(() {
    // 1. Register PDF format fallback
    registerFallbackValue(PdfPageFormat.standard);
    registerFallbackValue(OutputType.generic);

    // 2. Register LayoutCallback (Function) fallback
    // Mocktail needs this to handle the non-nullable onLayout callback
    registerFallbackValue((PdfPageFormat format) async => Uint8List(0));
  });

  setUp(() {
    service = PrinterService();
    mockPrintingPlatform = MockPrintingPlatform();
    PrintingPlatform.instance = mockPrintingPlatform;
    mockSale = MockSale();

    // ఇక్కడ మార్పులు చేయండి:
    when(
      () => mockSale.customerName,
    ).thenReturn("Manikanta"); // ఇంగ్లీష్ మాత్రమే
    when(() => mockSale.netPayable).thenReturn(2199.80);
    when(() => mockSale.id).thenReturn("TUQSYH12345");

    // ఒకవేళ మీ PdfInvoiceService ఐటమ్ నేమ్స్ ని ప్రింట్ చేస్తే, అక్కడ కూడా స్పెషల్ క్యారెక్టర్స్ ఉండకూడదు
    when(() => mockSale.items).thenReturn([]);

    when(() => mockSale.subtotal).thenReturn(2199.80);
    when(() => mockSale.totalSavings).thenReturn(222.20);
    when(() => mockSale.roundOff).thenReturn(0.0);
  });

  Widget createTestWidget(Function(BuildContext) callback) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => callback(context),
            child: const Text('Print'),
          ),
        ),
      ),
    );
  }

  group('PrinterService Scenarios', () {
    testWidgets('Scenario 1: Happy Path - Success', (tester) async {
      // satisfy analyzer by providing explicit types to any<T>()
      when(
        () => mockPrintingPlatform.layoutPdf(
          any<Printer?>(), // 1. printer (can be null)
          any<LayoutCallback>(), // 2. onLayout
          any<String>(), // 3. name
          any<PdfPageFormat>(), // 4. format
          any<bool>(), // 5. dynamicLayout
          any<bool>(), // 6. usePrinterSettings
          any<OutputType>(), // 7. outputType
          any<bool>(), // 8. forceCustomPrintPaper
        ),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        createTestWidget((context) {
          service.printReceipt(context, mockSale);
        }),
      );

      await tester.tap(find.text('Print'));
      await tester.pump();

      expect(find.text('Connecting to Printer...'), findsOneWidget);

      verify(
        () => mockPrintingPlatform.layoutPdf(
          any<Printer?>(),
          any<LayoutCallback>(),
          any<String>(),
          any<PdfPageFormat>(),
          any<bool>(),
          any<bool>(),
          any<OutputType>(),
          any<bool>(),
        ),
      ).called(1);
    });

    testWidgets('Scenario 3: Boundary Case (Short ID)', (tester) async {
      when(() => mockSale.id).thenReturn("ID1");

      when(
        () => mockPrintingPlatform.layoutPdf(
          any<Printer?>(), // 1. printer (can be null)
          any<LayoutCallback>(), // 2. onLayout
          any<String>(), // 3. name
          any<PdfPageFormat>(), // 4. format
          any<bool>(), // 5. dynamicLayout
          any<bool>(), // 6. usePrinterSettings
          any<OutputType>(), // 7. outputType
          any<bool>(), // 8. forceCustomPrintPaper
        ),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        createTestWidget((context) {
          service.printReceipt(context, mockSale);
        }),
      );

      await tester.tap(find.text('Print'));
      await tester.pump();

      // If the service doesn't check ID length, this catches the RangeError
    });
  });
}
