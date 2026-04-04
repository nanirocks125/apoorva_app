import 'package:apoorva_app/screens/organization/organization_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:apoorva_app/model/organization/organization.dart';
import 'package:apoorva_app/enum/form_mode.dart';
import 'package:apoorva_app/services/organization_service.dart';

class MockOrgService extends Mock implements OrganizationService {}

void main() {
  late MockOrgService mockService;
  late Organization testOrg;

  setUpAll(() {
    registerFallbackValue(
      Organization(
        name: '',
        status: '',
        createdAt: DateTime.now(),
        minVersion: '',
        accounts: [],
      ),
    );
  });

  setUp(() {
    mockService = MockOrgService();
    testOrg = Organization(
      id: 'org_123',
      name: 'Existing Shop',
      status: 'Active',
      createdAt: DateTime(2023),
      minVersion: '1.0.0',
      accounts: [],
    );
  });

  Widget createWidget(FormMode mode, {Organization? org}) {
    return MaterialApp(
      home: OrganizationFormScreen(
        mode: mode,
        org: org,
        orgService: mockService,
      ),
    );
  }

  group('OrganizationFormScreen - Initialization', () {
    testWidgets('View Mode disables fields and hides save button', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(FormMode.view, org: testOrg));

      final nameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Organization Name'),
      );
      expect(nameField.enabled, false);
      expect(find.text('Update Shop'), findsNothing);
      expect(find.text('Seed & Launch Shop'), findsNothing);
    });

    testWidgets('Edit Mode pre-fills data and shows update button', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(FormMode.edit, org: testOrg));

      expect(find.text('Existing Shop'), findsOneWidget);
      expect(find.text('Update Shop'), findsOneWidget);
    });
  });

  group('OrganizationFormScreen - Logic & Validation', () {
    testWidgets('Validation fails if name is empty', (tester) async {
      await tester.pumpWidget(createWidget(FormMode.create));

      await tester.tap(find.text('Seed & Launch Shop'));
      await tester.pump();

      expect(find.text('Name required'), findsOneWidget);
      verifyNever(() => mockService.createOrganization(any()));
    });

    testWidgets('Create Mode calls createOrganization and pops context', (
      tester,
    ) async {
      when(
        () => mockService.createOrganization(any()),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidget(FormMode.create));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Organization Name'),
        'New Business',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Initial Cash'),
        '500',
      );

      await tester.tap(find.text('Seed & Launch Shop'));
      await tester.pumpAndSettle();

      verify(() => mockService.createOrganization(any())).called(1);
      // Verify Navigator.pop happened (Screen is gone)
      expect(find.byType(OrganizationFormScreen), findsNothing);
    });

    testWidgets('Edit Mode calls updateOrganization with existing ID', (
      tester,
    ) async {
      when(
        () => mockService.updateOrganization(any()),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidget(FormMode.edit, org: testOrg));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Organization Name'),
        'Updated Name',
      );

      // Change Dropdown status
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inactive').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Update Shop'));
      await tester.pumpAndSettle();

      final capturedOrg =
          verify(
                () => mockService.updateOrganization(captureAny()),
              ).captured.first
              as Organization;
      expect(capturedOrg.id, testOrg.id);
      expect(capturedOrg.name, 'Updated Name');
      expect(capturedOrg.status, 'Inactive');
    });

    testWidgets('Shows SnackBar on service error', (tester) async {
      when(
        () => mockService.createOrganization(any()),
      ).thenThrow(Exception('Database Offline'));

      await tester.pumpWidget(createWidget(FormMode.create));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Organization Name'),
        'Fail Shop',
      );
      await tester.tap(find.text('Seed & Launch Shop'));
      await tester.pump(); // Start async
      await tester.pump(); // Catch error and show SnackBar

      expect(find.text('Error: Exception: Database Offline'), findsOneWidget);
    });
  });
}
