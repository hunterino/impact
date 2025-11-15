import 'package:json_annotation/json_annotation.dart';

part 'project_model.g.dart';

@JsonSerializable()
class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String organizerId;
  final String? organizerName;
  final String? organizerImageUrl;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime startDate;
  final DateTime endDate;
  final int minVolunteers;
  final int maxVolunteers;
  final int currentVolunteers;
  final List<String> requiredSkills;
  final List<String> causeAreas;
  final List<String>? tags;
  final String status;
  final double? pointsMultiplier;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? imageUrls;
  final bool isRecurring;
  final String? recurringPattern;
  
  const ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    this.organizerName,
    this.organizerImageUrl,
    required this.location,
    this.latitude,
    this.longitude,
    required this.startDate,
    required this.endDate,
    required this.minVolunteers,
    required this.maxVolunteers,
    required this.currentVolunteers,
    required this.requiredSkills,
    required this.causeAreas,
    this.tags,
    required this.status,
    this.pointsMultiplier,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrls,
    required this.isRecurring,
    this.recurringPattern,
  });
  
  // Whether the project is at capacity
  bool get isAtCapacity => currentVolunteers >= maxVolunteers;
  
  // Whether the project is in the future
  bool get isFuture => startDate.isAfter(DateTime.now());
  
  // Whether the project is in progress
  bool get isInProgress => 
      startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now());
  
  // Whether the project is completed
  bool get isCompleted => endDate.isBefore(DateTime.now());
  
  // Factory method to create project from JSON
  factory ProjectModel.fromJson(Map<String, dynamic> json) => 
      _$ProjectModelFromJson(json);
  
  // Method to convert project to JSON
  Map<String, dynamic> toJson() => _$ProjectModelToJson(this);
}
