// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectModel _$ProjectModelFromJson(Map<String, dynamic> json) => ProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      organizerId: json['organizerId'] as String,
      organizerName: json['organizerName'] as String?,
      organizerImageUrl: json['organizerImageUrl'] as String?,
      location: json['location'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      minVolunteers: (json['minVolunteers'] as num).toInt(),
      maxVolunteers: (json['maxVolunteers'] as num).toInt(),
      currentVolunteers: (json['currentVolunteers'] as num).toInt(),
      requiredSkills: (json['requiredSkills'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      causeAreas: (json['causeAreas'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      status: json['status'] as String,
      pointsMultiplier: (json['pointsMultiplier'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isRecurring: json['isRecurring'] as bool,
      recurringPattern: json['recurringPattern'] as String?,
    );

Map<String, dynamic> _$ProjectModelToJson(ProjectModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'organizerId': instance.organizerId,
      'organizerName': instance.organizerName,
      'organizerImageUrl': instance.organizerImageUrl,
      'location': instance.location,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'minVolunteers': instance.minVolunteers,
      'maxVolunteers': instance.maxVolunteers,
      'currentVolunteers': instance.currentVolunteers,
      'requiredSkills': instance.requiredSkills,
      'causeAreas': instance.causeAreas,
      'tags': instance.tags,
      'status': instance.status,
      'pointsMultiplier': instance.pointsMultiplier,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'imageUrls': instance.imageUrls,
      'isRecurring': instance.isRecurring,
      'recurringPattern': instance.recurringPattern,
    };
