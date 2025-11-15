// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PointsTransactionModel _$PointsTransactionModelFromJson(
        Map<String, dynamic> json) =>
    PointsTransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      transactionType: json['transactionType'] as String,
      points: (json['points'] as num).toInt(),
      sourceId: json['sourceId'] as String?,
      sourceType: json['sourceType'] as String?,
      description: json['description'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expirationDate: json['expirationDate'] == null
          ? null
          : DateTime.parse(json['expirationDate'] as String),
    );

Map<String, dynamic> _$PointsTransactionModelToJson(
        PointsTransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'transactionType': instance.transactionType,
      'points': instance.points,
      'sourceId': instance.sourceId,
      'sourceType': instance.sourceType,
      'description': instance.description,
      'timestamp': instance.timestamp.toIso8601String(),
      'expirationDate': instance.expirationDate?.toIso8601String(),
    };
