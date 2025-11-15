import 'package:json_annotation/json_annotation.dart';

part 'commitment_model.g.dart';

@JsonSerializable()
class CommitmentModel {
  final String id;
  final String userId;
  final String projectId;
  final String? projectSlotId;
  final String projectTitle;
  final String? projectImageUrl;
  final DateTime commitmentDate;
  final DateTime startTime;
  final DateTime endTime;
  final int numberOfVolunteers;
  final String status;
  final DateTime registeredAt;
  final DateTime? updatedAt;
  
  const CommitmentModel({
    required this.id,
    required this.userId,
    required this.projectId,
    this.projectSlotId,
    required this.projectTitle,
    this.projectImageUrl,
    required this.commitmentDate,
    required this.startTime,
    required this.endTime,
    required this.numberOfVolunteers,
    required this.status,
    required this.registeredAt,
    this.updatedAt,
  });
  
  // Whether the commitment is upcoming
  bool get isUpcoming => startTime.isAfter(DateTime.now());
  
  // Whether the commitment is in progress
  bool get isInProgress => 
      startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());
  
  // Whether the commitment is completed
  bool get isCompleted => endTime.isBefore(DateTime.now());
  
  // Duration of commitment in hours
  double get durationHours => 
      endTime.difference(startTime).inMinutes / 60.0;
  
  // Factory method to create commitment from JSON
  factory CommitmentModel.fromJson(Map<String, dynamic> json) => 
      _$CommitmentModelFromJson(json);
  
  // Method to convert commitment to JSON
  Map<String, dynamic> toJson() => _$CommitmentModelToJson(this);
}
