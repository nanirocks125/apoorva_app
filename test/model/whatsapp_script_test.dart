import 'package:flutter_test/flutter_test.dart';
import 'package:apoorva_app/model/whatsapp_script.dart';
import 'package:apoorva_app/model/sale.dart';

void main() {
  group('WhatsAppScript - formatMessage', () {
    test('should correctly replace all placeholders with sale data', () {
      // 1. Arrange (Set up the data)
      final script = WhatsAppScript(
        id: '1',
        title: 'Confirmation',
        content: 'Hi [NAME], total is [AMOUNT]. ID: [ID]',
        language: 'English',
      );

      final mockSale = Sale(
        id: 'SALE-123',
        customerName: 'Manikanta',
        netPayable: 1000.50,
        staffId: '',
        customerPhone: '',
        items: [],
        subtotal: 100,
        overallDiscountPercent: 10,
        overallDiscountAmount: 10,
        roundOff: 0,
        payments: {},
        timestamp: DateTime.now(),
        source: '',
        status: '',
        // ... fill other required fields with dummy data
      );

      // 2. Act (Run the code we're testing)
      final result = script.formatMessage(mockSale);

      // 3. Assert (Verify the result is what we expect)
      expect(result, contains('Hi Manikanta'));
      expect(result, contains('total is 1000.50'));
      expect(result, contains('ID: SALE-123'));
      expect(result, contains('✨ Care Tip:')); // Ensure the footer is added
    });
  });
}
