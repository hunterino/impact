import 'package:json_annotation/json_annotation.dart';

part 'reward_model.g.dart';

@JsonSerializable()
class RewardModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final double servDRCost;
  final double? retailValue;
  final String? imageUrl;
  final String? termsAndConditions;
  final String? vendorName;
  final String? vendorId;
  final int stockQuantity; // -1 means unlimited
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RewardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.servDRCost,
    this.retailValue,
    this.imageUrl,
    this.termsAndConditions,
    this.vendorName,
    this.vendorId,
    required this.stockQuantity,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Check if reward is out of stock (-1 means unlimited)
  bool get isOutOfStock => stockQuantity != -1 && stockQuantity <= 0;

  // Check if reward is available for redemption
  bool get isAvailable => isActive && !isOutOfStock;
  
  // Factory method to create reward from JSON
  factory RewardModel.fromJson(Map<String, dynamic> json) => 
      _$RewardModelFromJson(json);
  
  // Method to convert reward to JSON
  Map<String, dynamic> toJson() => _$RewardModelToJson(this);
}
