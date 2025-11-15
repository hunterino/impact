import 'package:json_annotation/json_annotation.dart';

part 'points_transaction_model.g.dart';

@JsonSerializable()
class PointsTransactionModel {
  final String id;
  final String userId;
  final String transactionType;
  final int points;
  final String? sourceId;
  final String? sourceType;
  final String? description;
  final DateTime timestamp;
  final DateTime? expirationDate;
  
  const PointsTransactionModel({
    required this.id,
    required this.userId,
    required this.transactionType,
    required this.points,
    this.sourceId,
    this.sourceType,
    this.description,
    required this.timestamp,
    this.expirationDate,
  });
  
  // Factory method to create transaction from JSON
  factory PointsTransactionModel.fromJson(Map<String, dynamic> json) => 
      _$PointsTransactionModelFromJson(json);
  
  // Method to convert transaction to JSON
  Map<String, dynamic> toJson() => _$PointsTransactionModelToJson(this);
}
