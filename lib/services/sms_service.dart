import 'package:http/http.dart' as http;

class SmsService {
  final String apiKey = "YOUR_3RD_PARTY_API_KEY";

  Future<bool> sendTransactionSms({
    required String phone,
    required String message,
  }) async {
    // Example for a typical Indian SMS Gateway (like Msg91 or TextLocal)
    final url = Uri.parse("https://api.example.com/v2/sms");

    try {
      final response = await http.post(
        url,
        body: {
          'apikey': apiKey,
          'number': phone,
          'message': message,
          'sender': 'APORVA', // Your registered DLT header
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print("SMS API Error: $e");
      return false;
    }
  }
}
