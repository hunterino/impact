import 'package:json_annotation/json_annotation.dart';

part 'service_record_model.g.dart';

@JsonSerializable()
class ServiceRecordModel {
  final String id;
  final String userId;
  final String projectId;
  final String? projectSlotId;
  final String projectTitle;
  final String? projectImageUrl;
  final DateTime serviceDate;
  final DateTime startTime;
  final DateTime endTime;
  final double hoursServed;
  final int pointsEarned;
  final String status;
  final List<String>? skills;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? notes;
  
  const ServiceRecordModel({
    required this.id,
    required this.userId,
    required this.projectId,
    this.projectSlotId,
    required this.projectTitle,
    this.projectImageUrl,
    required this.serviceDate,
    required this.startTime,
    required this.endTime,
    required this.hoursServed,
    required this.pointsEarned,
    required this.status,
    this.skills,
    this.verifiedBy,
    this.verifiedAt,
    this.notes,
  });
  
  // Factory method to create service record from JSON
  factory ServiceRecordModel.fromJson(Map<String, dynamic> json) => 
      _$ServiceRecordModelFromJson(json);
  
  // Method to convert service record to JSON
  Map<String, dynamic> toJson() => _$ServiceRecordModelToJson(this);
}
