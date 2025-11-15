import 'package:json_annotation/json_annotation.dart';

part 'team_model.g.dart';

@JsonSerializable()
class TeamModel {
  final String id;
  final String name;
  final String? description;
  final String leaderId;
  final String? imageUrl;
  final int memberCount;
  final List<String>? focusAreas;
  final int totalServiceHours;
  final int totalPoints;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  const TeamModel({
    required this.id,
    required this.name,
    this.description,
    required this.leaderId,
    this.imageUrl,
    required this.memberCount,
    this.focusAreas,
    required this.totalServiceHours,
    required this.totalPoints,
    required this.createdAt,
    this.updatedAt,
  });
  
  // Factory method to create team from JSON
  factory TeamModel.fromJson(Map<String, dynamic> json) => 
      _$TeamModelFromJson(json);
  
  // Method to convert team to JSON
  Map<String, dynamic> toJson() => _$TeamModelToJson(this);
}
