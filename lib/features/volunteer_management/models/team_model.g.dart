// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamModel _$TeamModelFromJson(Map<String, dynamic> json) => TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      leaderId: json['leaderId'] as String,
      imageUrl: json['imageUrl'] as String?,
      memberCount: (json['memberCount'] as num).toInt(),
      focusAreas: (json['focusAreas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      totalServiceHours: (json['totalServiceHours'] as num).toInt(),
      totalPoints: (json['totalPoints'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$TeamModelToJson(TeamModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'leaderId': instance.leaderId,
      'imageUrl': instance.imageUrl,
      'memberCount': instance.memberCount,
      'focusAreas': instance.focusAreas,
      'totalServiceHours': instance.totalServiceHours,
      'totalPoints': instance.totalPoints,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
