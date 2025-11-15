import 'package:json_annotation/json_annotation.dart';

part 'wallet_model.g.dart';

@JsonSerializable()
class WalletModel {
  final String id;
  final String userId;
  final int stbfPointsBalance;
  final double servDRBalance;
  final double servCoinBalance;
  final bool servCoinWalletActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.stbfPointsBalance,
    required this.servDRBalance,
    required this.servCoinBalance,
    required this.servCoinWalletActive,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Factory method to create wallet from JSON
  factory WalletModel.fromJson(Map<String, dynamic> json) => 
      _$WalletModelFromJson(json);
  
  // Method to convert wallet to JSON
  Map<String, dynamic> toJson() => _$WalletModelToJson(this);
}
