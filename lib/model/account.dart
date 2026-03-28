import 'package:apoorva_app/enum/account_type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'account.g.dart';

@JsonSerializable()
class Account {
  final String id;
  final String name;
  final AccountType type; // Cash, Bank, Digital Wallet
  final double currentBalance;

  Account({
    String? id,
    required this.name,
    required this.type,
    required this.currentBalance,
  }) : id = id ?? const Uuid().v4();

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
  Map<String, dynamic> toJson() => _$AccountToJson(this);
}
