// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redemption_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedemptionModel _$RedemptionModelFromJson(Map<String, dynamic> json) =>
    RedemptionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      rewardId: json['rewardId'] as String,
      servDRCost: (json['servDRCost'] as num).toDouble(),
      status: json['status'] as String,
      redemptionCode: json['redemptionCode'] as String?,
      fulfillmentInstructions: json['fulfillmentInstructions'] as String?,
      redemptionDate: DateTime.parse(json['redemptionDate'] as String),
      fulfilledAt: json['fulfilledAt'] == null
          ? null
          : DateTime.parse(json['fulfilledAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$RedemptionModelToJson(RedemptionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'rewardId': instance.rewardId,
      'servDRCost': instance.servDRCost,
      'status': instance.status,
      'redemptionCode': instance.redemptionCode,
      'fulfillmentInstructions': instance.fulfillmentInstructions,
      'redemptionDate': instance.redemptionDate.toIso8601String(),
      'fulfilledAt': instance.fulfilledAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
