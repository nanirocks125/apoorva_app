// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'internal_transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InternalTransfer _$InternalTransferFromJson(Map<String, dynamic> json) =>
    InternalTransfer(
      id: json['id'] as String,
      fromAccountId: json['from_account_id'] as String,
      toAccountId: json['to_account_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      transferType: json['transfer_type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$InternalTransferToJson(InternalTransfer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'from_account_id': instance.fromAccountId,
      'to_account_id': instance.toAccountId,
      'amount': instance.amount,
      'transfer_type': instance.transferType,
      'timestamp': instance.timestamp.toIso8601String(),
    };
