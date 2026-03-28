import 'package:json_annotation/json_annotation.dart';

@JsonEnum(alwaysCreate: true)
enum AccountType {
  @JsonValue('cash')
  cash, // For physical shop drawer [cite: 72, 106]

  @JsonValue('bank')
  bank, // For SBI or other accounts [cite: 76]

  @JsonValue('upi')
  upi, // For digital wallet/UPI tracking [cite: 74]
}
