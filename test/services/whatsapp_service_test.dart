import 'package:apoorva_app/services/whatsapp_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:apoorva_app/model/whatsapp_script.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FakeLaunchOptions extends Fake implements LaunchOptions {}

class MockUrlLauncher extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}

// We need this to force Firestore errors for catch blocks
class MockFirestore extends Mock implements FirebaseFirestore {}
// class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
// class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLaunchOptions());
    registerFallbackValue(Uri());
    registerFallbackValue(Uri.parse('https://wa.me'));
    registerFallbackValue(LaunchMode.externalApplication);
  });

  late FakeFirebaseFirestore fakeDb;
  late WhatsAppService whatsappService;
  late MockUrlLauncher mockLauncher;
  const String orgId = 'apoorva_mangalagiri';

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    whatsappService = WhatsAppService(db: fakeDb);
    mockLauncher = MockUrlLauncher();
    UrlLauncherPlatform.instance = mockLauncher;
  });

  group('WhatsAppService - Firestore Success Paths', () {
    test('saveScript should generate a doc ID and save data', () async {
      final script = WhatsAppScript(
        id: '',
        title: 'Welcome',
        content: 'Hi!',
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
    });

    test('getScriptsStream should return typed scripts list', () async {
      await fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('scripts')
          .add({
            'id': 's1',
            'title': 'Test Script',
            'content': 'Hello',
            'language': 'Telugu',
          });

      final stream = whatsappService.getScriptsStream(orgId);
      final results = await stream.first;

      expect(results.length, 1);
      expect(results.first.title, 'Test Script');
    });

    test('getUnsentSales should filter correctly', () async {
      final salesColl = fakeDb
          .collection('organizations')
          .doc(orgId)
          .collection('sales');

      // Valid mock data to prevent "Null is not a subtype of String" errors
      final baseSale = {
        'id': 'sale_today',
        'customerName': 'Today User',
        'customerPhone': '123',
        'timestamp': Timestamp.now(),
        'items': [],
        'netPayable': 100.0,
        'subtotal': 0.0,
        'overallDiscountPercent': 0.0,
        'overallDiscountAmount': 0.0,
        'staffId': 'staff_01',
        'roundOff': 0.0,
        'payments': <String, dynamic>{},
        'source': 'Walk-in',
        'status': 'Completed',
        'whatsappStatus': 'unsent',
      };

      await salesColl.add({
        ...baseSale,
        'customerName': 'Unsent User',
        'whatsappStatus': 'unsent',
      });
      await salesColl.add({
        ...baseSale,
        'customerName': 'Sent User',
        'whatsappStatus': 'sent',
      });

      final stream = whatsappService.getUnsentSales(orgId);
      final results = await stream.first;

      expect(results.length, 1);
      expect(results.first.customerName, 'Unsent User');
    });
  });

  group('WhatsAppService - Firestore Error Handling', () {
    test('saveScript should throw exception on Firestore failure', () async {
      final mockDb = MockFirestore();
      final errorService = WhatsAppService(db: mockDb);

      when(
        () => mockDb.collection(any()),
      ).thenThrow(Exception('Firestore Down'));

      expect(
        () => errorService.saveScript(
          orgId,
          WhatsAppScript(id: '', title: 'T', content: 'C', language: 'L'),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
  group('WhatsAppService - Launch Logic & Fallbacks', () {
    const String phone = '918121971462';
    const String message = 'Hello!';

    test(
      'launchWhatsApp should try whatsapp:// scheme first on mobile',
      () async {
        when(
          () => mockLauncher.launchUrl(any(), any()),
        ).thenAnswer((_) async => true);

        await whatsappService.launchWhatsApp(phone: phone, message: message);

        // 1. Capture the argument as a String
        final capturedUrlString =
            verify(
                  () => mockLauncher.launchUrl(captureAny(), any()),
                ).captured.first
                as String;

        // 2. Parse it back to Uri to verify the components
        final capturedUri = Uri.parse(capturedUrlString);

        expect(capturedUri.scheme, 'whatsapp');
        // whatsapp:// use query parameters for phone and text
        expect(capturedUri.queryParameters['phone'], phone);
        expect(capturedUri.queryParameters['text'], message);
      },
    );

    test(
      'launchWhatsApp should use fallback https://wa.me if first attempt fails',
      () async {
        // 1. Setup Mock Behavior
        var callCount = 0;
        when(
          () => mockLauncher.launchUrl(
            any<String>(), // ప్లాట్‌ఫారమ్ ఇంటర్‌ఫేస్ String తీసుకుంటుంది
            any<LaunchOptions>(), // ఇది positional argument, named కాదు
          ),
        ).thenAnswer((_) async {
          callCount++;
          return callCount != 1;
        });

        // 2. Execute Service
        await whatsappService.launchWhatsApp(phone: phone, message: message);

        // 3. Capture & Verify
        final capturedCalls = verify(
          () => mockLauncher.launchUrl(
            captureAny<String>(),
            any<LaunchOptions>(),
          ),
        ).captured;

        expect(capturedCalls.length, 2);
        expect(capturedCalls[0], contains('whatsapp://'));
        expect(capturedCalls[1], contains('https://wa.me'));
      },
    );
  });
}
