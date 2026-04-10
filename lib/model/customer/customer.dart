import 'package:apoorva_app/utilities/nullable_timestamp_converter.dart';
import 'package:apoorva_app/utilities/timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer.g.dart';

@JsonSerializable(explicitToJson: true)
class Customer {
  final String name;
  final String phone;

  @TimestampConverter()
  final DateTime createdAt;

  @NullableTimestampConverter()
  DateTime? lastPurchaseDate;

  @JsonKey(defaultValue: 0)
  int totalSales;

  @JsonKey(defaultValue: 0)
  double totalAmountSpent;

  Customer({
    required this.name,
    required this.phone,
    required this.lastPurchaseDate,
    this.totalSales = 0,
    this.totalAmountSpent = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // --- JSON SERIALIZATION ---
  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerToJson(this);

  String get tenure {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    final days = difference.inDays;

    if (days < 30) {
      return days == 0 ? 'Joined Today' : 'Customer for $days days';
    } else if (days < 365) {
      final months = (days / 30).floor();
      return 'Customer for $months month${months > 1 ? 's' : ''}';
    } else {
      final years = (days / 365).floor();
      final remainingMonths = ((days % 365) / 30).floor();

      String tenureText = 'Customer for $years year${years > 1 ? 's' : ''}';
      if (remainingMonths > 0) {
        tenureText +=
            ', $remainingMonths month${remainingMonths > 1 ? 's' : ''}';
      }
      return tenureText;
    }
  }
}
