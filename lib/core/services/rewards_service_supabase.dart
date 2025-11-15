import 'package:flutter/foundation.dart';
import 'package:serve_to_be_free/core/services/supabase_service.dart';
import 'package:serve_to_be_free/features/rewards/models/points_transaction_model.dart';
import 'package:serve_to_be_free/features/rewards/models/serv_dr_transaction_model.dart';
import 'package:serve_to_be_free/features/rewards/models/reward_model.dart';
import 'package:serve_to_be_free/features/rewards/models/redemption_model.dart';
import 'package:serve_to_be_free/features/rewards/models/wallet_model.dart';

/// Rewards Service using Supabase
/// This replaces the MQTT-based rewards service with direct database access
class RewardsServiceSupabase {
  final SupabaseService _supabaseService;

  RewardsServiceSupabase({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  // ================================================
  // WALLET OPERATIONS
  // ================================================

  /// Get user wallet with all balances
  Future<WalletModel> getUserWallet(String userId) async {
    try {
      // Call the database function to get wallet summary
      final response = await _supabaseService.rpc<Map<String, dynamic>>(
        'get_user_wallet_summary',
        params: {'p_user_id': userId},
      );

      // Map the response to WalletModel
      return WalletModel(
        id: response['user_id'] as String,
        userId: response['user_id'] as String,
        stbfPointsBalance: response['points_balance'] as int,
        servDRBalance: (response['serv_dr_balance'] as num).toDouble(),
        servCoinBalance: (response['serv_coin_balance'] as num).toDouble(),
        servCoinWalletActive: response['serv_coin_wallet_active'] as bool,
        createdAt: DateTime.parse(response['updated_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
      );
    } catch (e) {
      if (kDebugMode) {
        print('ERROR getting user wallet: $e');
      }
      throw Exception('Failed to get wallet: $e');
    }
  }

  /// Convert STBF Points to SERV DR
  /// Conversion rate: 100 Points = 1 SERV DR
  Future<String> convertPointsToServDR(String userId, int pointsAmount) async {
    try {
      final transactionId = await _supabaseService.rpc<String>(
        'convert_points_to_serv_dr',
        params: {
          'p_user_id': userId,
          'p_points_amount': pointsAmount,
        },
      );

      return transactionId;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR converting points to SERV DR: $e');
      }
      throw Exception('Failed to convert points: $e');
    }
  }

  /// Convert SERV DR to SERV Coin
  /// Requires activated wallet. Conversion rate: 1 SERV DR = 1 SERV Coin
  Future<String> convertServDRToServCoin(String userId, double servDRAmount) async {
    try {
      final transactionId = await _supabaseService.rpc<String>(
        'convert_serv_dr_to_serv_coin',
        params: {
          'p_user_id': userId,
          'p_serv_dr_amount': servDRAmount,
        },
      );

      return transactionId;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR converting SERV DR to SERV Coin: $e');
      }
      throw Exception('Failed to convert SERV DR: $e');
    }
  }

  /// Activate SERV Coin wallet for user
  Future<bool> activateServCoinWallet(String userId) async {
    try {
      final result = await _supabaseService.rpc<bool>(
        'activate_serv_coin_wallet',
        params: {'p_user_id': userId},
      );

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR activating SERV Coin wallet: $e');
      }
      throw Exception('Failed to activate SERV Coin wallet: $e');
    }
  }

  // ================================================
  // TRANSACTION HISTORY
  // ================================================

  /// Get points transactions (not implemented yet - would need database query)
  Future<List<PointsTransactionModel>> getPointsTransactions(
    String userId,
    {int page = 1, int pageSize = 20}
  ) async {
    try {
      // Query transactions table filtered by user and currency type
      final response = await _supabaseService.read<Map<String, dynamic>>(
        'transactions',
        filters: {
          'user_id': userId,
          'currency': 'points',
        },
        orderBy: 'created_at',
        ascending: false,
        limit: pageSize,
        offset: (page - 1) * pageSize,
      );

      // Map to PointsTransactionModel (simplified - you may need to adjust)
      return response.map((tx) => PointsTransactionModel(
        id: tx['id'] as String,
        userId: tx['user_id'] as String,
        transactionType: tx['type'] as String,
        points: tx['amount'] as int,
        sourceId: tx['metadata']?['source_id'] as String?,
        sourceType: tx['metadata']?['source_type'] as String?,
        description: tx['metadata']?['description'] as String?,
        timestamp: DateTime.parse(tx['created_at'] as String),
        expirationDate: tx['expires_at'] != null ? DateTime.parse(tx['expires_at'] as String) : null,
      )).toList();
    } catch (e) {
      if (kDebugMode) {
        print('ERROR getting points transactions: $e');
      }
      throw Exception('Failed to get points transactions: $e');
    }
  }

  /// Get SERV DR transactions
  Future<List<ServDRTransactionModel>> getServDRTransactions(
    String userId,
    {int page = 1, int pageSize = 20}
  ) async {
    try {
      final response = await _supabaseService.read<Map<String, dynamic>>(
        'transactions',
        filters: {
          'user_id': userId,
          'currency': 'serv_dr',
        },
        orderBy: 'created_at',
        ascending: false,
        limit: pageSize,
        offset: (page - 1) * pageSize,
      );

      return response.map((tx) => ServDRTransactionModel(
        id: tx['id'] as String,
        userId: tx['user_id'] as String,
        transactionType: tx['type'] as String,
        amount: (tx['amount'] as num).toDouble(),
        sourceId: tx['metadata']?['source_id'] as String?,
        description: tx['metadata']?['description'] as String?,
        timestamp: DateTime.parse(tx['created_at'] as String),
        blockchainTxId: tx['metadata']?['blockchain_tx_id'] as String?,
        status: tx['status'] as String? ?? 'completed',
      )).toList();
    } catch (e) {
      if (kDebugMode) {
        print('ERROR getting SERV DR transactions: $e');
      }
      throw Exception('Failed to get SERV DR transactions: $e');
    }
  }

  // ================================================
  // REWARDS MARKETPLACE
  // ================================================

  /// Get available rewards from database
  Future<List<RewardModel>> getAvailableRewards({
    String? category,
    double? maxServDRCost,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Build filters
      final filters = <String, dynamic>{'is_active': true};

      if (category != null) {
        filters['category'] = category;
      }

      // Note: For maxServDRCost, we need to use a range filter
      Map<String, dynamic>? costFilter;
      if (maxServDRCost != null) {
        costFilter = {'serv_dr_cost': {'\$lte': maxServDRCost}};
      }

      // Query rewards table
      final response = await _supabaseService.read<Map<String, dynamic>>(
        'rewards',
        filters: costFilter != null ? {...filters, ...costFilter} : filters,
        orderBy: 'created_at',
        ascending: false,
        limit: pageSize,
        offset: (page - 1) * pageSize,
      );

      // Map to RewardModel with field name conversions
      return response.map((reward) => RewardModel.fromJson({
        'id': reward['id'],
        'title': reward['title'],
        'description': reward['description'] ?? '',
        'category': reward['category'],
        'servDRCost': reward['serv_dr_cost'],
        'retailValue': reward['retail_value'],
        'imageUrl': reward['image_url'],
        'termsAndConditions': reward['terms_and_conditions'],
        'vendorName': reward['vendor_name'],
        'vendorId': reward['vendor_id'],
        'stockQuantity': reward['stock_quantity'],
        'isActive': reward['is_active'],
        'createdAt': reward['created_at'],
        'updatedAt': reward['updated_at'],
      })).toList();
    } catch (e) {
      if (kDebugMode) {
        print('ERROR getting available rewards: $e');
      }
      throw Exception('Failed to get rewards: $e');
    }
  }

  /// Get reward by ID
  Future<RewardModel> getRewardById(String rewardId) async {
    try {
      final response = await _supabaseService.getById<Map<String, dynamic>>(
        'rewards',
        rewardId,
      );

      return RewardModel.fromJson({
        'id': response['id'],
        'title': response['title'],
        'description': response['description'] ?? '',
        'category': response['category'],
        'servDRCost': response['serv_dr_cost'],
        'retailValue': response['retail_value'],
        'imageUrl': response['image_url'],
        'termsAndConditions': response['terms_and_conditions'],
        'vendorName': response['vendor_name'],
        'vendorId': response['vendor_id'],
        'stockQuantity': response['stock_quantity'],
        'isActive': response['is_active'],
        'createdAt': response['created_at'],
        'updatedAt': response['updated_at'],
      });
    } catch (e) {
      if (kDebugMode) {
        print('ERROR getting reward by ID: $e');
      }
      throw Exception('Failed to get reward: $e');
    }
  }

  /// Redeem a reward
  Future<RedemptionModel> redeemReward(String userId, String rewardId) async {
    try {
      // Call the atomic redemption function
      final redemptionId = await _supabaseService.rpc<String>(
        'redeem_reward_atomic',
        params: {
          'p_user_id': userId,
          'p_reward_id': rewardId,
        },
      );

      // Fetch the redemption details
      final response = await _supabaseService.getById<Map<String, dynamic>>(
        'redemptions',
        redemptionId,
      );

      return RedemptionModel.fromJson({
        'id': response['id'],
        'userId': response['user_id'],
        'rewardId': response['reward_id'],
        'servDRCost': response['serv_dr_cost'],
        'status': response['status'],
        'redemptionCode': response['redemption_code'],
        'fulfillmentInstructions': response['fulfillment_instructions'],
        'redemptionDate': response['redemption_date'],
        'fulfilledAt': response['fulfilled_at'],
        'expiresAt': response['expires_at'],
        'createdAt': response['created_at'],
        'updatedAt': response['updated_at'],
      });
    } catch (e) {
      if (kDebugMode) {
        print('ERROR redeeming reward: $e');
      }
      throw Exception('Failed to redeem reward: $e');
    }
  }

  /// Get user's redemptions
  Future<List<RedemptionModel>> getUserRedemptions(
    String userId,
    {String? status, int page = 1, int pageSize = 20}
  ) async {
    try {
      final filters = <String, dynamic>{'user_id': userId};

      if (status != null) {
        filters['status'] = status;
      }

      final response = await _supabaseService.read<Map<String, dynamic>>(
        'redemptions',
        filters: filters,
        orderBy: 'created_at',
        ascending: false,
        limit: pageSize,
        offset: (page - 1) * pageSize,
      );

      return response.map((redemption) => RedemptionModel.fromJson({
        'id': redemption['id'],
        'userId': redemption['user_id'],
        'rewardId': redemption['reward_id'],
        'servDRCost': redemption['serv_dr_cost'],
        'status': redemption['status'],
        'redemptionCode': redemption['redemption_code'],
        'fulfillmentInstructions': redemption['fulfillment_instructions'],
        'redemptionDate': redemption['redemption_date'],
        'fulfilledAt': redemption['fulfilled_at'],
        'expiresAt': redemption['expires_at'],
        'createdAt': redemption['created_at'],
        'updatedAt': redemption['updated_at'],
      })).toList();
    } catch (e) {
      if (kDebugMode) {
        print('ERROR getting user redemptions: $e');
      }
      throw Exception('Failed to get redemptions: $e');
    }
  }

  /// Get redemption by ID
  Future<RedemptionModel> getRedemptionById(String userId, String redemptionId) async {
    try {
      final response = await _supabaseService.getById<Map<String, dynamic>>(
        'redemptions',
        redemptionId,
      );

      // Verify it belongs to the user
      if (response['user_id'] != userId) {
        throw Exception('Redemption not found or access denied');
      }

      return RedemptionModel.fromJson({
        'id': response['id'],
        'userId': response['user_id'],
        'rewardId': response['reward_id'],
        'servDRCost': response['serv_dr_cost'],
        'status': response['status'],
        'redemptionCode': response['redemption_code'],
        'fulfillmentInstructions': response['fulfillment_instructions'],
        'redemptionDate': response['redemption_date'],
        'fulfilledAt': response['fulfilled_at'],
        'expiresAt': response['expires_at'],
        'createdAt': response['created_at'],
        'updatedAt': response['updated_at'],
      });
    } catch (e) {
      if (kDebugMode) {
        print('ERROR getting redemption by ID: $e');
      }
      throw Exception('Failed to get redemption: $e');
    }
  }
}

/// Provider class for Rewards (using Supabase)
class RewardsProviderSupabase with ChangeNotifier {
  final RewardsServiceSupabase _rewardsService;

  WalletModel? _wallet;
  List<PointsTransactionModel> _pointsTransactions = [];
  List<ServDRTransactionModel> _servDRTransactions = [];
  List<RewardModel> _availableRewards = [];
  RewardModel? _selectedReward;
  List<RedemptionModel> _userRedemptions = [];
  RedemptionModel? _selectedRedemption;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  WalletModel? get wallet => _wallet;
  List<PointsTransactionModel> get pointsTransactions => _pointsTransactions;
  List<ServDRTransactionModel> get servDRTransactions => _servDRTransactions;
  List<RewardModel> get availableRewards => _availableRewards;
  RewardModel? get selectedReward => _selectedReward;
  List<RedemptionModel> get userRedemptions => _userRedemptions;
  RedemptionModel? get selectedRedemption => _selectedRedemption;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  RewardsProviderSupabase(this._rewardsService);

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Fetch user wallet
  Future<void> fetchUserWallet(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _wallet = await _rewardsService.getUserWallet(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch available rewards
  Future<void> fetchAvailableRewards({
    String? category,
    double? maxServDRCost,
    int page = 1,
    int pageSize = 20,
    bool reset = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rewards = await _rewardsService.getAvailableRewards(
        category: category,
        maxServDRCost: maxServDRCost,
        page: page,
        pageSize: pageSize,
      );

      if (reset) {
        _availableRewards = rewards;
      } else {
        _availableRewards.addAll(rewards);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch reward details
  Future<void> fetchRewardDetails(String rewardId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedReward = await _rewardsService.getRewardById(rewardId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Redeem reward
  Future<RedemptionModel?> redeemReward(String userId, String rewardId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final redemption = await _rewardsService.redeemReward(userId, rewardId);

      // Update redemptions list
      _userRedemptions.insert(0, redemption);

      // Refresh wallet to update balances
      await fetchUserWallet(userId);

      _isLoading = false;
      notifyListeners();
      return redemption;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Fetch user redemptions
  Future<void> fetchUserRedemptions(
    String userId,
    {String? status, int page = 1, int pageSize = 20, bool reset = true}
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final redemptions = await _rewardsService.getUserRedemptions(
        userId,
        status: status,
        page: page,
        pageSize: pageSize,
      );

      if (reset) {
        _userRedemptions = redemptions;
      } else {
        _userRedemptions.addAll(redemptions);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Convert points to SERV DR
  Future<bool> convertPointsToServDR(String userId, int pointsAmount) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _rewardsService.convertPointsToServDR(userId, pointsAmount);

      // Refresh wallet to update balances
      await fetchUserWallet(userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Convert SERV DR to SERV Coin
  Future<bool> convertServDRToServCoin(String userId, double servDRAmount) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _rewardsService.convertServDRToServCoin(userId, servDRAmount);

      // Refresh wallet to update balances
      await fetchUserWallet(userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Activate SERV Coin wallet
  Future<bool> activateServCoinWallet(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _rewardsService.activateServCoinWallet(userId);

      if (success) {
        // Refresh wallet to update status
        await fetchUserWallet(userId);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
