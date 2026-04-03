import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:apoorva_app/services/bluetooth_thermal_printer_service.dart';
import 'package:apoorva_app/model/sale.dart';

import 'invoice_document_sharing_service_test.dart';

// Mocks
class MockBlueThermalPrinter extends Mock implements BlueThermalPrinter {}

class MockBluetoothDevice extends Mock implements BluetoothDevice {}

class MockSale extends Mock implements Sale {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // Add this line
  late BluetoothThermalPrinterService service;
  late MockBlueThermalPrinter mockBluetooth;
  late MockSale mockSale;

  setUp(() {
    mockBluetooth = MockBlueThermalPrinter();
    service = BluetoothThermalPrinterService(bluetooth: mockBluetooth);
    mockSale = MockSale();

    // Setup basic mock data
    when(() => mockSale.customerName).thenReturn("Manikanta");
    when(() => mockSale.netPayable).thenReturn(1500.0);
    when(() => mockSale.id).thenReturn("SALE123");
    when(() => mockSale.items).thenReturn([]);
  });

  group('BluetoothThermalPrinterService Tests', () {
    test('Should not call connect() if already connected', () async {
      final mockDevice = MockBluetoothDevice();
      when(() => mockDevice.name).thenReturn("Seznik Printer");

      when(() => mockBluetooth.isConnected).thenAnswer((_) async => true);
      when(
        () => mockBluetooth.getBondedDevices(),
      ).thenAnswer((_) async => [mockDevice]);

      // Execution
      // Note: You'll need to inject the mockBluetooth into the service
      // via constructor for this to work effectively in a real test.
    });

    test(
      'Should show error snackbar when Bluetooth connection fails',
      () async {
        final mockDevice = MockBluetoothDevice();
        when(() => mockDevice.name).thenReturn("Seznik");

        when(() => mockBluetooth.isConnected).thenAnswer((_) async => false);
        when(
          () => mockBluetooth.getBondedDevices(),
        ).thenAnswer((_) async => [mockDevice]);
        when(
          () => mockBluetooth.connect(mockDevice),
        ).thenThrow(Exception("Connection Timeout"));

        // Verify that error handling logic is triggered
      },
    );
  });
}
