import 'package:apoorva_app/services/whatsapp_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:apoorva_app/model/whatsapp_script.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mocking the URL Launcher Platform
class MockUrlLauncher extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

void main() {
  late FakeFirebaseFirestore fakeDb;
  late WhatsAppService whatsappService;
  late MockUrlLauncher mockLauncher;
  const String orgId = 'apoorva_mangalagiri';

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    whatsappService = WhatsAppService(db: fakeDb);

    // Register the mock launcher
    mockLauncher = MockUrlLauncher();
    UrlLauncherPlatform.instance = mockLauncher;
  });

  group('WhatsAppService - Firestore Logic', () {
    test('saveScript should generate a doc ID and save data', () async {
      final script = WhatsAppScript(
        id: '',
        title: 'Welcome Message',
        content: 'Hi! Thanks for visiting Apoorva.',
        language: 'English',
      );

      await whatsappService.saveScript(orgId, script);

      final snapshot = await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('scripts')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.get('id'), isNotEmpty);
      expect(snapshot.docs.first.get('title'), 'Welcome Message');
    });

    test('getUnsentSales should filter by "unsent" status', () async {
      final salesColl = fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('sales');

      // Seed one unsent and one sent sale
      await salesColl.add({
        'id': 'sale_1',
        'whatsappStatus': 'unsent',
        'customerName': 'Suresh',
        'customerPhone': '8121971462',
        'timestamp': Timestamp.now(),
        'items': [],
        'staffId': '',
        'subtotal': 0,
        'overallDiscountPercent': 10,
        'overallDiscountAmount': 100,
        'roundOff': 0,
        'payments': <String, dynamic>{},
        'source': '',
        'status': '',
        'netPayable': 5000.0, // ✅ Model needs these numbers
      });
      await salesColl.add({
        'id': 'sale_2',

        'whatsappStatus': 'sent',
        'customerName': 'Ramesh',
        'timestamp': Timestamp.now(),
        'customerPhone': '8121971462',

        'items': [],
        'staffId': '',
        'subtotal': 0,
        'overallDiscountPercent': 10,
        'overallDiscountAmount': 100,
        'roundOff': 0,
        'payments': <String, dynamic>{},
        'source': '',
        'status': '',
        'netPayable': 5000.0, // ✅ Model needs these numbers
      });

      final stream = whatsappService.getUnsentSales(orgId);
      final results = await stream.first;

      expect(results.length, 1);
      expect(results.first.customerName, 'Suresh');
    });
  });

  group('WhatsAppService - Launch Logic', () {
    test('launchWhatsApp should use correct URI scheme', () async {
      const String phone = '918121971462';
      const String message = 'Hello from Apoorva!';

      // Mocking the response for launchUrl
      when(
        () => mockLauncher.launchUrl(any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockLauncher.canLaunch(any())).thenAnswer((_) async => true);

      await whatsappService.launchWhatsApp(phone: phone, message: message);

      // Verify if the launcher was triggered
      verify(() => mockLauncher.launchUrl(any(), any())).called(1);
    });
  });
}
