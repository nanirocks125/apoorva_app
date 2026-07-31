import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// Project Imports
import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/model/sale_item.dart';
import 'package:apoorva_app/services/receipt_communication_service.dart';

class FakeLaunchOptions extends Fake implements LaunchOptions {}

class MockUrlLauncher extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

class MockSale extends Mock implements Sale {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLaunchOptions());
  });

  late ReceiptCommunicationService service;
  late MockUrlLauncher mockPlatform;
  late MockSale mockSale;

  setUp(() {
    service = ReceiptCommunicationService();
    mockPlatform = MockUrlLauncher();
    UrlLauncherPlatform.instance = mockPlatform;
    mockSale = MockSale();

    // Default Stubs
    when(() => mockSale.customerName).thenReturn("Manikanta");
    when(() => mockSale.customerPhone).thenReturn("9876543210");
    when(() => mockSale.id).thenReturn("TUQSYH12345");
    when(() => mockSale.netPayable).thenReturn(1500.0);
    when(() => mockSale.subtotal).thenReturn(1600.0);
    when(() => mockSale.totalSavings).thenReturn(100.0);
    when(() => mockSale.roundOff).thenReturn(-10.0);
  });

  group('sendWhatsAppTextOnly', () {
    testWidgets('Validation: Empty Phone SnackBar', (tester) async {
      when(() => mockSale.customerPhone).thenReturn("");

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    service.sendWhatsAppTextOnly(context, mockSale),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump();
      expect(find.text('Phone number not provided!'), findsOneWidget);
    });

    testWidgets('Message Check: Item with Discount (Strike-through active)', (
      tester,
    ) async {
      when(() => mockSale.items).thenReturn([
        SaleItem(
          categoryName: "Gold Ring",
          stickerPrice: 1000,
          finalPrice: 900,
          qty: 1,
          categoryId: '1',
          discountType: .finalPrice,
        ),
      ]);
      when(() => mockPlatform.canLaunch(any())).thenAnswer((_) async => true);
      when(
        () => mockPlatform.launchUrl(any(), any()),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    service.sendWhatsAppTextOnly(context, mockSale),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));

      final capturedUrl =
          verify(
                () => mockPlatform.launchUrl(captureAny(), any()),
              ).captured.single
              as String;
      final decodedMsg = Uri.decodeComponent(capturedUrl.split('text=')[1]);

      // Assertions for Strike-through and Discount line
      expect(decodedMsg, contains("MRP: ~Rs 1000~ Rs 900.00"));
      expect(decodedMsg, contains("Qty: 1 x Rs 900.00"));
      expect(decodedMsg, contains("Item Total: *Rs 900.00*"));
      expect(decodedMsg, contains("✨ *YOU SAVED Rs 100.00!* ✨"));
    });

    testWidgets('Message Check: Item No Discount (No Strike-through)', (
      tester,
    ) async {
      when(() => mockSale.items).thenReturn([
        SaleItem(
          categoryName: "Silver Coin",
          stickerPrice: 500,
          finalPrice: 500,
          qty: 1,
          categoryId: '2',
          discountType: .finalPrice,
        ),
      ]);
      when(() => mockSale.totalSavings).thenReturn(0.0);
      when(() => mockPlatform.canLaunch(any())).thenAnswer((_) async => true);
      when(
        () => mockPlatform.launchUrl(any(), any()),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    service.sendWhatsAppTextOnly(context, mockSale),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));

      final capturedUrl =
          verify(
                () => mockPlatform.launchUrl(captureAny(), any()),
              ).captured.single
              as String;
      final decodedMsg = Uri.decodeComponent(capturedUrl.split('text=')[1]);

      // Assertions: No ~ symbols, No DISCOUNT text for that item
      expect(decodedMsg, contains('MRP: Rs 500.00'));
      expect(decodedMsg, contains('Qty: 1 x Rs 500.00'));
      expect(decodedMsg, contains('Item Total: *Rs 500.00*'));
      expect(decodedMsg, isNot(contains("~Rs 500~")));
      expect(decodedMsg, isNot(contains("DISCOUNT *Rs 0.00*")));
    });
  });

  group('sendTextMessage', () {
    testWidgets('Full Format Check with RoundOff', (tester) async {
      when(() => mockSale.items).thenReturn([
        SaleItem(
          categoryName: "Chain",
          stickerPrice: 2000,
          finalPrice: 1800,
          qty: 1,
          categoryId: '3',
          discountType: .finalPrice,
        ),
      ]);
      when(() => mockPlatform.canLaunch(any())).thenAnswer((_) async => true);
      when(
        () => mockPlatform.launchUrl(any(), any()),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => service.sendTextMessage(context, mockSale),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));

      final capturedUrl =
          verify(
                () => mockPlatform.launchUrl(captureAny(), any()),
              ).captured.single
              as String;
      final decodedMsg = Uri.decodeComponent(capturedUrl.split('body=')[1]);

      expect(decodedMsg, contains("APOORVA JEWELLERY"));
      expect(decodedMsg, contains("MRP: Rs 2000"));
      expect(decodedMsg, contains("Discount: Rs 200"));
      expect(decodedMsg, contains("Extra Disc: -Rs 10.00")); // Roundoff check
      expect(decodedMsg, contains("Net Payable: Rs 1500.00"));
    });

    testWidgets('Error Handling: canLaunchUrl returns false', (tester) async {
      when(() => mockSale.items).thenReturn([]);
      when(() => mockPlatform.canLaunch(any())).thenAnswer((_) async => false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => service.sendTextMessage(context, mockSale),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Could not open SMS app'), findsOneWidget);
    });

    testWidgets('Error Handling: Launch throws exception', (tester) async {
      when(() => mockSale.items).thenReturn([]);
      when(() => mockPlatform.canLaunch(any())).thenAnswer((_) async => true);
      when(
        () => mockPlatform.launchUrl(any(), any()),
      ).thenThrow(Exception("Failed"));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => service.sendTextMessage(context, mockSale),
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Could not open SMS app'), findsOneWidget);
    });
  });
}
