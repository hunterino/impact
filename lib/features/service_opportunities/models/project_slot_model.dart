import 'package:json_annotation/json_annotation.dart';

part 'project_slot_model.g.dart';

@JsonSerializable()
class ProjectSlotModel {
  final String id;
  final String projectId;
  final DateTime startTime;
  final DateTime endTime;
  final int maxCapacity;
  final int currentVolunteers;
  final String status;
  final List<String>? requiredRoles;
  
  const ProjectSlotModel({
    required this.id,
    required this.projectId,
    required this.startTime,
    required this.endTime,
    required this.maxCapacity,
    required this.currentVolunteers,
    required this.status,
    this.requiredRoles,
  });
  
  // Whether the slot is at capacity
  bool get isAtCapacity => currentVolunteers >= maxCapacity;
  
  // Whether the slot is in the future
  bool get isFuture => startTime.isAfter(DateTime.now());
  
  // Whether the slot is in progress
  bool get isInProgress => 
      startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());
  
  // Whether the slot is completed
  bool get isCompleted => endTime.isBefore(DateTime.now());
  
  // Duration of the slot in hours
  double get durationHours => 
      endTime.difference(startTime).inMinutes / 60.0;
  
  // Factory method to create slot from JSON
  factory ProjectSlotModel.fromJson(Map<String, dynamic> json) => 
      _$ProjectSlotModelFromJson(json);
  
  // Method to convert slot to JSON
  Map<String, dynamic> toJson() => _$ProjectSlotModelToJson(this);
}
