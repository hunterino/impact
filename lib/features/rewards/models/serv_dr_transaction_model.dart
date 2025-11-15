import 'package:json_annotation/json_annotation.dart';

part 'serv_dr_transaction_model.g.dart';

@JsonSerializable()
class ServDRTransactionModel {
  final String id;
  final String userId;
  final String transactionType;
  final double amount;
  final String? sourceId;
  final String? description;
  final DateTime timestamp;
  final String? blockchainTxId;
  final String status;
  
  const ServDRTransactionModel({
    required this.id,
    required this.userId,
    required this.transactionType,
    required this.amount,
    this.sourceId,
    this.description,
    required this.timestamp,
    this.blockchainTxId,
    required this.status,
  });
  
  // Factory method to create transaction from JSON
  factory ServDRTransactionModel.fromJson(Map<String, dynamic> json) => 
      _$ServDRTransactionModelFromJson(json);
  
  // Method to convert transaction to JSON
  Map<String, dynamic> toJson() => _$ServDRTransactionModelToJson(this);
}
