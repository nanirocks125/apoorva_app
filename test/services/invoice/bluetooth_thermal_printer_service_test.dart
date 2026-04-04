import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:printing/printing.dart';
import 'package:apoorva_app/services/bluetooth_thermal_printer_service.dart';
import 'package:apoorva_app/model/sale.dart';

// Mocks
class MockBlueThermalPrinter extends Mock implements BlueThermalPrinter {}

class MockBluetoothDevice extends Mock implements BluetoothDevice {}

class MockSale extends Mock implements Sale {}

class FakeSale extends Fake implements Sale {}

class MockPrinterWrapper extends Mock implements PrinterWrapper {}

class MockPdfRaster extends Mock implements PdfRaster {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(MockBluetoothDevice());
    registerFallbackValue(Uint8List(0));

    // ADD THIS LINE:
    registerFallbackValue(FakeSale());
  });

  late BluetoothThermalPrinterService service;
  late MockBlueThermalPrinter mockBluetooth;
  late MockPrinterWrapper mockWrapper;
  late MockSale mockSale;

  setUp(() {
    mockBluetooth = MockBlueThermalPrinter();
    mockWrapper =
        MockPrinterWrapper(); // This should be an instance of MockPrinterWrapper

    // Use named arguments (bluetooth: and wrapper:)
    service = BluetoothThermalPrinterService(
      bluetooth: mockBluetooth,
      wrapper: mockWrapper,
    );

    mockSale = MockSale();

    // Stub Sale data
    when(() => mockSale.customerName).thenReturn("Test Customer");
    when(() => mockSale.netPayable).thenReturn(100.0);
    when(() => mockSale.id).thenReturn("123");
    when(() => mockSale.items).thenReturn([]);
    when(() => mockSale.subtotal).thenReturn(100.0);
    when(() => mockSale.totalSavings).thenReturn(0.0);
    when(() => mockSale.roundOff).thenReturn(0.0);
  });

  group('BluetoothThermalPrinterService Tests', () {
    testWidgets('Full Success Path (Connection -> PDF -> Raster -> Print)', (
      tester,
    ) async {
      final device = MockBluetoothDevice();
      when(() => device.name).thenReturn("Seznik Printer");

      // Connection Stubs
      when(() => mockBluetooth.isConnected).thenAnswer((_) async => false);
      when(
        () => mockBluetooth.getBondedDevices(),
      ).thenAnswer((_) async => [device]);
      when(() => mockBluetooth.connect(any())).thenAnswer((_) async => true);

      // PDF & Raster Stubs
      final fakePdfBytes = Uint8List.fromList([1, 2, 3]);
      final mockPage = MockPdfRaster();
      when(
        () => mockWrapper.generateReceipt(any()),
      ).thenAnswer((_) async => fakePdfBytes);
      when(
        () => mockWrapper.rasterize(any()),
      ).thenAnswer((_) => Stream.fromIterable([mockPage]));
      when(
        () => mockPage.toPng(),
      ).thenAnswer((_) async => Uint8List.fromList([4, 5, 6]));

      // Printer Action Stubs
      when(
        () => mockBluetooth.printImageBytes(any()),
      ).thenAnswer((_) async => {});
      when(() => mockBluetooth.printNewLine()).thenAnswer((_) async => {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      service.printReceiptViaBluetooth(context, mockSale),
                  child: const Text("Print"),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify full logic execution
      verify(() => mockBluetooth.connect(device)).called(1);
      verify(() => mockBluetooth.printImageBytes(any())).called(1);
      verify(() => mockBluetooth.printNewLine()).called(2); // From _feedPaper
      expect(find.text("Printing Receipt..."), findsOneWidget);
    });

    testWidgets('Shows error SnackBar when no printer found', (tester) async {
      when(() => mockBluetooth.isConnected).thenAnswer((_) async => true);
      when(() => mockBluetooth.getBondedDevices()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    try {
                      await service.printReceiptViaBluetooth(context, mockSale);
                    } catch (_) {}
                  },
                  child: const Text("Print"),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.textContaining("Seznik Printer not found"), findsOneWidget);
    });

    testWidgets('Handles Bluetooth Connection errors', (tester) async {
      final device = MockBluetoothDevice();
      when(() => device.name).thenReturn("MPT-II");
      when(() => mockBluetooth.isConnected).thenAnswer((_) async => false);
      when(
        () => mockBluetooth.getBondedDevices(),
      ).thenAnswer((_) async => [device]);
      when(
        () => mockBluetooth.connect(any()),
      ).thenThrow(Exception("Bonding Failed"));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    try {
                      await service.printReceiptViaBluetooth(context, mockSale);
                    } catch (_) {}
                  },
                  child: const Text("Print"),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("Bluetooth Error: Exception: Bonding Failed"),
        findsOneWidget,
      );
    });
  });
}
