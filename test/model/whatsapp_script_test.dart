import 'package:apoorva_app/model/sale.dart';
import 'package:apoorva_app/model/whatsapp_script.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/enum/payment_mode.dart';

void main() {
  group('WhatsAppScript Model Tests', () {
    // 1. Setup Mock Sale for Placeholder Testing
    final mockSale = Sale(
      id: 'SALE_101',
      staffId: 'staff_01',
      customerPhone: '8121971462',
      customerName: 'Suresh Kumar',
      items: [],
      subtotal: 5000.0,
      overallDiscountPercent: 0,
      overallDiscountAmount: 0,
      roundOff: 0,
      netPayable: 5000.0,
      payments: {PaymentMode.cash: 5000.0},
      timestamp: DateTime.now(),
      source: 'Walk-in',
      status: 'Completed',
    );

    group('Constructor & Logic', () {
      test('should initialize fields correctly', () {
        final script = WhatsAppScript(
          id: 'script_01',
          title: 'Thank You Message',
          content: 'Hello [NAME], thanks for shopping!',
          language: 'English',
        );

        expect(script.title, 'Thank You Message');
        expect(script.language, 'English');
      });

      test('formatMessage should replace all placeholders correctly', () {
        final script = WhatsAppScript(
          id: 's1',
          title: 'Invoice',
          content: 'Hi [NAME]! Your bill for Sale #[ID] is ₹[AMOUNT].',
          language: 'Tanglish',
        );

        final formatted = script.formatMessage(mockSale);

        // Verify placeholders are gone and replaced with real data
        expect(formatted, contains('Hi Suresh Kumar!'));
        expect(formatted, contains('Sale #SALE_101'));
        expect(formatted, contains('is ₹5000.00'));

        // Verify the hardcoded Care Tip is appended
        expect(
          formatted,
          contains('✨ Care Tip: Keep your jewelry away from perfumes'),
        );
      });
    });

    group('JSON Serialization', () {
      test('toJson should produce a valid Map', () {
        final script = WhatsAppScript(
          id: 'script_99',
          title: 'Festival Offer',
          content: 'Special 10% off for you!',
          language: 'Telugu',
        );

        final json = script.toJson();

        expect(json['title'], 'Festival Offer');
        expect(json['language'], 'Telugu');
        expect(json['id'], 'script_99');
      });

      test('fromJson should reconstruct the object accurately', () {
        final json = {
          'id': 'json_id_123',
          'title': 'New Arrivals',
          'content': 'Check out our new gold bangles!',
          'language': 'English',
        };

        final script = WhatsAppScript.fromJson(json);

        expect(script.id, 'json_id_123');
        expect(script.title, 'New Arrivals');
        expect(script.content, contains('bangles'));
      });
    });

    test('copyWithId should change the ID but keep content intact', () {
      final script = WhatsAppScript(
        id: 'old_id',
        title: 'Draft',
        content: 'Original Content',
        language: 'English',
      );

      final updated = script.copyWithId('new_id_777');

      expect(updated.id, 'new_id_777');
      expect(updated.title, 'Draft');
      expect(identical(script, updated), isFalse);
    });
  });
}
