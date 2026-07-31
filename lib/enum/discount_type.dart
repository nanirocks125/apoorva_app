enum DiscountType { percentage, amount, finalPrice }

extension DiscountTypeExtension on DiscountType {
  /// The label used in the SegmentedButton
  String get segmentLabel {
    switch (this) {
      case DiscountType.percentage:
        return '% Off';
      case DiscountType.amount:
        return '₹ Discount';
      case DiscountType.finalPrice:
        return 'Final ₹';
    }
  }

  /// The label for the TextField
  String get fieldLabel {
    switch (this) {
      case DiscountType.percentage:
        return 'Discount Percentage';
      case DiscountType.amount:
        return 'Enter Discount Amount';
      case DiscountType.finalPrice:
        return 'Enter Final Price';
    }
  }

  /// The currency or percent symbol prefix
  String get prefix {
    switch (this) {
      case DiscountType.percentage:
        return '';
      default:
        return '₹';
    }
  }
}
