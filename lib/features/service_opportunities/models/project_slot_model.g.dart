// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_slot_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectSlotModel _$ProjectSlotModelFromJson(Map<String, dynamic> json) =>
    ProjectSlotModel(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      maxCapacity: (json['maxCapacity'] as num).toInt(),
      currentVolunteers: (json['currentVolunteers'] as num).toInt(),
      status: json['status'] as String,
      requiredRoles: (json['requiredRoles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ProjectSlotModelToJson(ProjectSlotModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'maxCapacity': instance.maxCapacity,
      'currentVolunteers': instance.currentVolunteers,
      'status': instance.status,
      'requiredRoles': instance.requiredRoles,
    };
