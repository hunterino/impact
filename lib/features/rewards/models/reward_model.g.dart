// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RewardModel _$RewardModelFromJson(Map<String, dynamic> json) => RewardModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      servDRCost: (json['servDRCost'] as num).toDouble(),
      retailValue: (json['retailValue'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      termsAndConditions: json['termsAndConditions'] as String?,
      vendorName: json['vendorName'] as String?,
      vendorId: json['vendorId'] as String?,
      stockQuantity: (json['stockQuantity'] as num).toInt(),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$RewardModelToJson(RewardModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'servDRCost': instance.servDRCost,
      'retailValue': instance.retailValue,
      'imageUrl': instance.imageUrl,
      'termsAndConditions': instance.termsAndConditions,
      'vendorName': instance.vendorName,
      'vendorId': instance.vendorId,
      'stockQuantity': instance.stockQuantity,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
