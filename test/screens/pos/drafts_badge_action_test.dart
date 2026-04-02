import 'dart:async';
import 'package:apoorva_app/screens/pos/draft_badge_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:apoorva_app/screens/pos/pos_provider.dart';
import 'package:apoorva_app/model/cart/draft_cart.dart';
import 'package:apoorva_app/services/draft_cart_service.dart';

// Mocks
class MockPosProvider extends Mock implements PosProvider {}

class MockDraftCartService extends Mock implements DraftCartService {}

void main() {
  late MockPosProvider mockProvider;
  late MockDraftCartService mockService;
  late StreamController<List<DraftCart>> streamController;

  setUp(() {
    mockProvider = MockPosProvider();
    mockService = MockDraftCartService();
    streamController = StreamController<List<DraftCart>>();

    when(() => mockProvider.orgId).thenReturn('apoorva_mangalagiri');

    // DraftCartService().getDraftsStream() ని మాక్ చేయడం
    // గమనిక: మీ కోడ్ లో నేరుగా DraftCartService() అని ఇన్‌స్టాంటియేట్ చేస్తుంటే
    // దాన్ని టెస్ట్ చేయడం కష్టం. ఒక సీనియర్ డెవలపర్ గా మీరు దాన్ని DI (Dependency Injection) కి మార్చాలి.
  });

  tearDown(() {
    streamController.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            ChangeNotifierProvider<PosProvider>.value(
              value: mockProvider,
              child: DraftsBadgeAction(service: mockService),
            ),
          ],
        ),
      ),
    );
  }

  group('DraftsBadgeAction Tests', () {
    testWidgets('Should show badge with count 0 when stream has no data', (
      tester,
    ) async {
      // Empty stream
      when(
        () => mockService.getDraftsStream(any()),
      ).thenAnswer((_) => streamController.stream);

      await tester.pumpWidget(createWidgetUnderTest());
      streamController.add([]); // Empty list
      await tester.pump();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Should show correct count in badge when data arrives', (
      tester,
    ) async {
      when(
        () => mockService.getDraftsStream(any()),
      ).thenAnswer((_) => streamController.stream);

      await tester.pumpWidget(createWidgetUnderTest());

      final drafts = [
        DraftCart(
          id: '1',
          customerName: 'Client A',
          customerPhone: '',
          items: [],
          total: 100,
          createdAt: DateTime.now(),
        ),
        DraftCart(
          id: '2',
          customerName: 'Client B',
          customerPhone: '',
          items: [],
          total: 200,
          createdAt: DateTime.now(),
        ),
      ];

      streamController.add(drafts);
      await tester.pump();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('Tapping the button should open bottom sheet and show drafts', (
      tester,
    ) async {
      when(
        () => mockService.getDraftsStream(any()),
      ).thenAnswer((_) => streamController.stream);

      await tester.pumpWidget(createWidgetUnderTest());

      final drafts = [
        DraftCart(
          id: '1',
          customerName: 'Manikanta',
          customerPhone: '',
          items: [],
          total: 100,
          createdAt: DateTime.now(),
        ),
      ];
      streamController.add(drafts);
      await tester.pump();

      // Icon క్లిక్ చేయడం
      await tester.tap(find.byIcon(Icons.folder_open));
      await tester.pumpAndSettle(); // Bottom sheet ఓపెన్ అయ్యే వరకు ఆగాలి

      expect(find.text('HOLD BILLS (DRAFTS)'), findsOneWidget);
      expect(find.text('Manikanta'), findsOneWidget);
    });
  });
}
