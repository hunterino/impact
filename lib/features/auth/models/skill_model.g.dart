// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillModel _$SkillModelFromJson(Map<String, dynamic> json) => SkillModel(
      id: json['id'] as String,
      name: json['name'] as String,
      proficiencyLevel: (json['proficiencyLevel'] as num).toInt(),
      category: json['category'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      lastUsed: json['lastUsed'] == null
          ? null
          : DateTime.parse(json['lastUsed'] as String),
    );

Map<String, dynamic> _$SkillModelToJson(SkillModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'proficiencyLevel': instance.proficiencyLevel,
      'category': instance.category,
      'isVerified': instance.isVerified,
      'lastUsed': instance.lastUsed?.toIso8601String(),
    };
