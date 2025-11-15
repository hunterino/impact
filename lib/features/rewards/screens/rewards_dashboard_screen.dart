import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/services/rewards_service.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/rewards/screens/convert_points_screen.dart';
import 'package:serve_to_be_free/features/rewards/screens/my_rewards_screen.dart';
import 'package:serve_to_be_free/features/rewards/screens/points_history_screen.dart';
import 'package:serve_to_be_free/features/rewards/screens/rewards_marketplace_screen.dart';
import 'package:serve_to_be_free/features/rewards/screens/serv_dr_history_screen.dart';
import 'package:serve_to_be_free/features/rewards/widgets/reward_category_card.dart';
import 'package:serve_to_be_free/features/rewards/widgets/wallet_summary_card.dart';

import 'convert_serv_dr_screeen.dart';

class RewardsDashboardScreen extends StatefulWidget {
  const RewardsDashboardScreen({super.key});

  @override
  State<RewardsDashboardScreen> createState() => _RewardsDashboardScreenState();
}

class _RewardsDashboardScreenState extends State<RewardsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);

    if (authProvider.user != null) {
      try {
        await rewardsProvider.fetchUserWallet(authProvider.user!.id);
        await rewardsProvider.fetchAvailableRewards(pageSize: 5);
        await rewardsProvider.fetchUserRedemptions(
          authProvider.user!.id,
          status: 'active',
          pageSize: 5,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading rewards data: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _navigateToPointsHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PointsHistoryScreen(),
      ),
    );
  }

  void _navigateToServDRHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ServDRHistoryScreen(),
      ),
    );
  }

  void _navigateToRewardsMarketplace() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RewardsMarketplaceScreen(),
      ),
    );
  }

  void _navigateToMyRewards() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyRewardsScreen(),
      ),
    );
  }

  void _navigateToConvertPoints() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConvertPointsScreen(),
      ),
    );
  }

  void _navigateToConvertServDR() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConvertServDRScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<RewardsProvider>(
        builder: (context, rewardsProvider, child) {
          final wallet = rewardsProvider.wallet;
          final isLoading = rewardsProvider.isLoading;

          if (isLoading && wallet == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet Summary
                  if (wallet != null)
                    WalletSummaryCard(
                      wallet: wallet,
                      onPointsHistoryTap: _navigateToPointsHistory,
                      onServDRHistoryTap: _navigateToServDRHistory,
                    ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToConvertPoints,
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Convert Points'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: wallet?.servCoinWalletActivated == true
                              ? _navigateToConvertServDR
                              : null,
                          icon: const Icon(Icons.currency_exchange),
                          label: const Text('Convert to SERV Coin'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Category Cards
                  const Text(
                    'Reward Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        RewardCategoryCard(
                          icon: Icons.shopping_bag,
                          title: 'Retail',
                          color: Colors.blue,
                          onTap: () => _navigateToRewardsMarketplace(),
                        ),
                        const SizedBox(width: 12),
                        RewardCategoryCard(
                          icon: Icons.restaurant,
                          title: 'Dining',
                          color: Colors.orange,
                          onTap: () => _navigateToRewardsMarketplace(),
                        ),
                        const SizedBox(width: 12),
                        RewardCategoryCard(
                          icon: Icons.movie,
                          title: 'Entertainment',
                          color: Colors.purple,
                          onTap: () => _navigateToRewardsMarketplace(),
                        ),
                        const SizedBox(width: 12),
                        RewardCategoryCard(
                          icon: Icons.card_giftcard,
                          title: 'Gift Cards',
                          color: Colors.red,
                          onTap: () => _navigateToRewardsMarketplace(),
                        ),
                        const SizedBox(width: 12),
                        RewardCategoryCard(
                          icon: Icons.more_horiz,
                          title: 'More',
                          color: Colors.green,
                          onTap: () => _navigateToRewardsMarketplace(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Featured Rewards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Featured Rewards',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _navigateToRewardsMarketplace,
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (rewardsProvider.availableRewards.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No featured rewards available'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rewardsProvider.availableRewards.length,
                      itemBuilder: (context, index) {
                        final reward = rewardsProvider.availableRewards[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: reward.imageUrl != null
                                ? Image.network(
                              reward.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.card_giftcard,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(reward.title),
                            subtitle: Text(reward.merchantName),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${reward.servDRCost} SERV DR',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Expires: ${reward.validUntil.day}/${reward.validUntil.month}/${reward.validUntil.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              // Navigate to reward details
                            },
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // My Rewards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Rewards',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _navigateToMyRewards,
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (rewardsProvider.userRedemptions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No active rewards'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rewardsProvider.userRedemptions.length,
                      itemBuilder: (context, index) {
                        final redemption = rewardsProvider.userRedemptions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: redemption.rewardImageUrl != null
                                ? Image.network(
                              redemption.rewardImageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.card_giftcard,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(redemption.rewardTitle),
                            subtitle: Text(redemption.merchantName),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.successColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Expires: ${redemption.expiresAt.day}/${redemption.expiresAt.month}/${redemption.expiresAt.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              // Navigate to redemption details
                            },
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}




