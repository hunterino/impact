import 'package:json_annotation/json_annotation.dart';

part 'team_member_model.g.dart';

@JsonSerializable()
class TeamMemberModel {
  final String userId;
  final String teamId;
  final String role;
  final DateTime joinedAt;
  final int contributedHours;
  final int contributedPoints;
  
  const TeamMemberModel({
    required this.userId,
    required this.teamId,
    required this.role,
    required this.joinedAt,
    required this.contributedHours,
    required this.contributedPoints,
  });
  
  // Factory method to create team member from JSON
  factory TeamMemberModel.fromJson(Map<String, dynamic> json) => 
      _$TeamMemberModelFromJson(json);
  
  // Method to convert team member to JSON
  Map<String, dynamic> toJson() => _$TeamMemberModelToJson(this);
}
