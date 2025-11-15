import 'package:json_annotation/json_annotation.dart';

part 'skill_model.g.dart';

@JsonSerializable()
class SkillModel {
  final String id;
  final String name;
  final int proficiencyLevel;
  final String? category;
  final bool isVerified;
  final DateTime? lastUsed;

  const SkillModel({
    required this.id,
    required this.name,
    required this.proficiencyLevel,
    this.category,
    this.isVerified = false,
    this.lastUsed,
  });

  // Factory method to create skill from JSON
  factory SkillModel.fromJson(Map<String, dynamic> json) => 
      _$SkillModelFromJson(json);

  // Method to convert skill to JSON
  Map<String, dynamic> toJson() => _$SkillModelToJson(this);

  // Copy with method to create a new instance with some properties changed
  SkillModel copyWith({
    String? name,
    int? proficiencyLevel,
    String? category,
    bool? isVerified,
    DateTime? lastUsed,
  }) {
    return SkillModel(
      id: id,
      name: name ?? this.name,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      category: category ?? this.category,
      isVerified: isVerified ?? this.isVerified,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
