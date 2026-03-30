import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

enum PaymentMode {
  @JsonValue('cash')
  cash,

  @JsonValue('upi')
  upi,

  @JsonValue('card')
  card,

  @JsonValue('credit') // అప్పు (Credit) మీద ఇచ్చే సేల్స్ కోసం
  credit;

  // --- UI Helpers ---
  String get displayName {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI / PhonePe';
      case PaymentMode.card:
        return 'Card';
      case PaymentMode.credit:
        return 'Store Credit';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMode.cash:
        return Icons.payments_outlined;
      case PaymentMode.upi:
        return Icons.qr_code_scanner_outlined;
      case PaymentMode.card:
        return Icons.credit_card_outlined;
      case PaymentMode.credit:
        return Icons.person_outline;
    }
  }
}
