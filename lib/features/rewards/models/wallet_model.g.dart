// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletModel _$WalletModelFromJson(Map<String, dynamic> json) => WalletModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      stbfPointsBalance: (json['stbfPointsBalance'] as num).toInt(),
      servDRBalance: (json['servDRBalance'] as num).toDouble(),
      servCoinBalance: (json['servCoinBalance'] as num).toDouble(),
      servCoinWalletActive: json['servCoinWalletActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$WalletModelToJson(WalletModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'stbfPointsBalance': instance.stbfPointsBalance,
      'servDRBalance': instance.servDRBalance,
      'servCoinBalance': instance.servCoinBalance,
      'servCoinWalletActive': instance.servCoinWalletActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
