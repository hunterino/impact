// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamMemberModel _$TeamMemberModelFromJson(Map<String, dynamic> json) =>
    TeamMemberModel(
      userId: json['userId'] as String,
      teamId: json['teamId'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      contributedHours: (json['contributedHours'] as num).toInt(),
      contributedPoints: (json['contributedPoints'] as num).toInt(),
    );

Map<String, dynamic> _$TeamMemberModelToJson(TeamMemberModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'teamId': instance.teamId,
      'role': instance.role,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'contributedHours': instance.contributedHours,
      'contributedPoints': instance.contributedPoints,
    };
