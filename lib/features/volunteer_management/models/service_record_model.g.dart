// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceRecordModel _$ServiceRecordModelFromJson(Map<String, dynamic> json) =>
    ServiceRecordModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      projectId: json['projectId'] as String,
      projectSlotId: json['projectSlotId'] as String?,
      projectTitle: json['projectTitle'] as String,
      projectImageUrl: json['projectImageUrl'] as String?,
      serviceDate: DateTime.parse(json['serviceDate'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      hoursServed: (json['hoursServed'] as num).toDouble(),
      pointsEarned: (json['pointsEarned'] as num).toInt(),
      status: json['status'] as String,
      skills:
          (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList(),
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ServiceRecordModelToJson(ServiceRecordModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'projectId': instance.projectId,
      'projectSlotId': instance.projectSlotId,
      'projectTitle': instance.projectTitle,
      'projectImageUrl': instance.projectImageUrl,
      'serviceDate': instance.serviceDate.toIso8601String(),
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'hoursServed': instance.hoursServed,
      'pointsEarned': instance.pointsEarned,
      'status': instance.status,
      'skills': instance.skills,
      'verifiedBy': instance.verifiedBy,
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'notes': instance.notes,
    };
