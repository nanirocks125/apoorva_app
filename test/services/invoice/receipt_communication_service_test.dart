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

// Mocks
class MockUrlLauncher extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

class MockSale extends Mock implements Sale {}

class MockSaleItem extends Mock implements SaleItem {}

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

    // Default Sale Data
    when(() => mockSale.customerName).thenReturn("Manikanta");
    when(() => mockSale.id).thenReturn("TUQSYH12345");
    when(() => mockSale.netPayable).thenReturn(1500.0);
    when(() => mockSale.subtotal).thenReturn(1600.0);
    when(() => mockSale.totalSavings).thenReturn(100.0);
    when(() => mockSale.roundOff).thenReturn(-10.0);
    when(() => mockSale.items).thenReturn([
      SaleItem(
        categoryName: "Gold Ring",
        stickerPrice: 1000,
        finalPrice: 900,
        qty: 1,
        categoryId: '1',
      ),
    ]);
  });

  group('sendWhatsAppTextOnly Scenarios', () {
    testWidgets('Should show SnackBar when phone number is empty', (
      tester,
    ) async {
      when(() => mockSale.customerPhone).thenReturn("");

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      service.sendWhatsAppTextOnly(context, mockSale),
                  child: const Text('Tap'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('Phone number not provided!'), findsOneWidget);
      verifyNever(() => mockPlatform.launchUrl(any(), any()));
    });

    testWidgets('Should launch WhatsApp with 91 prefix for 10-digit phone', (
      tester,
    ) async {
      when(() => mockSale.customerPhone).thenReturn("9876543210");
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

      // Verify phone formatting logic (919876543210)
      final captured =
          verify(
                () => mockPlatform.launchUrl(captureAny(), any()),
              ).captured.single
              as String;
      expect(captured, contains("phone=919876543210"));
      expect(captured, contains("APOORVA%20JEWELLERY"));
    });
  });

  group('sendTextMessage Scenarios', () {
    testWidgets(
      'Should format SMS URL correctly with cleaned phone and savings',
      (tester) async {
        when(() => mockSale.customerPhone).thenReturn("987-654-3210");
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

        final captured =
            verify(
                  () => mockPlatform.launchUrl(captureAny(), any()),
                ).captured.single
                as String;
        expect(captured, startsWith("sms:919876543210"));
        expect(captured, contains("YOU%20SAVED%20Rs%20100.00"));
      },
    );

    testWidgets('Should show error SnackBar when SMS app cannot be opened', (
      tester,
    ) async {
      when(() => mockSale.customerPhone).thenReturn("9876543210");
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

    testWidgets(
      'Should handle zero savings scenario (hiding savings message)',
      (tester) async {
        when(() => mockSale.customerPhone).thenReturn("9876543210");
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
                  onPressed: () => service.sendTextMessage(context, mockSale),
                  child: const Text('Tap'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Tap'));

        final captured =
            verify(
                  () => mockPlatform.launchUrl(captureAny(), any()),
                ).captured.single
                as String;
        expect(captured, isNot(contains("YOU%20SAVED")));
      },
    );
  });
}
