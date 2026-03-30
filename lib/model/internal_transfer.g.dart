// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'internal_transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InternalTransfer _$InternalTransferFromJson(Map<String, dynamic> json) =>
    InternalTransfer(
      id: json['id'] as String,
      fromAccountId: json['fromAccountId'] as String,
      toAccountId: json['toAccountId'] as String,
      amount: (json['amount'] as num).toDouble(),
      transferType: json['transferType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$InternalTransferToJson(InternalTransfer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromAccountId': instance.fromAccountId,
      'toAccountId': instance.toAccountId,
      'amount': instance.amount,
      'transferType': instance.transferType,
      'timestamp': instance.timestamp.toIso8601String(),
    };
