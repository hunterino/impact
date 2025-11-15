// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commitment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommitmentModel _$CommitmentModelFromJson(Map<String, dynamic> json) =>
    CommitmentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      projectId: json['projectId'] as String,
      projectSlotId: json['projectSlotId'] as String?,
      projectTitle: json['projectTitle'] as String,
      projectImageUrl: json['projectImageUrl'] as String?,
      commitmentDate: DateTime.parse(json['commitmentDate'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      numberOfVolunteers: (json['numberOfVolunteers'] as num).toInt(),
      status: json['status'] as String,
      registeredAt: DateTime.parse(json['registeredAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CommitmentModelToJson(CommitmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'projectId': instance.projectId,
      'projectSlotId': instance.projectSlotId,
      'projectTitle': instance.projectTitle,
      'projectImageUrl': instance.projectImageUrl,
      'commitmentDate': instance.commitmentDate.toIso8601String(),
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'numberOfVolunteers': instance.numberOfVolunteers,
      'status': instance.status,
      'registeredAt': instance.registeredAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
