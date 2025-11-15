// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serv_dr_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServDRTransactionModel _$ServDRTransactionModelFromJson(
        Map<String, dynamic> json) =>
    ServDRTransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      transactionType: json['transactionType'] as String,
      amount: (json['amount'] as num).toDouble(),
      sourceId: json['sourceId'] as String?,
      description: json['description'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      blockchainTxId: json['blockchainTxId'] as String?,
      status: json['status'] as String,
    );

Map<String, dynamic> _$ServDRTransactionModelToJson(
        ServDRTransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'transactionType': instance.transactionType,
      'amount': instance.amount,
      'sourceId': instance.sourceId,
      'description': instance.description,
      'timestamp': instance.timestamp.toIso8601String(),
      'blockchainTxId': instance.blockchainTxId,
      'status': instance.status,
    };
