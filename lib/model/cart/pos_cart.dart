// The complete Checkout Session
import 'package:apoorva_app/enum/payment_mode.dart';
import 'package:apoorva_app/model/cart/cart_item.dart';

class PosCart {
  List<CartItem> items = [];
  double flatDiscount = 0.0; // Cart-level flat rupee discount [cite: 39]
  PaymentMode paymentMode = PaymentMode.cash; // Cash, UPI, or Card
  String? customerPhone;
  String? customerName;
  String? socialSource; // Instagram, WhatsApp, etc. [cite: 40]

  // Final total after all discounts
  double get totalPayable {
    double subtotal = items.fold(0, (sum, item) => sum + item.finalPrice);
    return (subtotal - flatDiscount).clamp(0.0, double.infinity);
  }

  double get totalMRP {
    return items.fold(0, (sum, item) => sum + item.mrp * item.quantity);
  }

  double get totalFinalPrice {
    return items.fold(0, (sum, item) => sum + item.finalPrice * item.quantity);
  }

  double get totalDiscountOnMRP {
    return totalMRP - totalFinalPrice;
  }
}
