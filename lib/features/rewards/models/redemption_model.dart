import 'package:json_annotation/json_annotation.dart';

part 'redemption_model.g.dart';

@JsonSerializable()
class RedemptionModel {
  final String id;
  final String userId;
  final String rewardId;
  final double servDRCost;
  final String status; // pending, processing, fulfilled, cancelled, expired
  final String? redemptionCode;
  final String? fulfillmentInstructions;
  final DateTime redemptionDate;
  final DateTime? fulfilledAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RedemptionModel({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.servDRCost,
    required this.status,
    this.redemptionCode,
    this.fulfillmentInstructions,
    required this.redemptionDate,
    this.fulfilledAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Check if redemption is expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  // Check if redemption is active
  bool get isActive =>
      !isExpired && (status == 'pending' || status == 'processing');
  
  // Factory method to create redemption from JSON
  factory RedemptionModel.fromJson(Map<String, dynamic> json) => 
      _$RedemptionModelFromJson(json);
  
  // Method to convert redemption to JSON
  Map<String, dynamic> toJson() => _$RedemptionModelToJson(this);
}
