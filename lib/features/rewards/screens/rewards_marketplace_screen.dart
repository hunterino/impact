import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/services/rewards_service_supabase.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/rewards/widgets/reward_card.dart';
import 'package:serve_to_be_free/features/rewards/screens/reward_detail_screen.dart';

class RewardsMarketplaceScreen extends StatefulWidget {
  const RewardsMarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<RewardsMarketplaceScreen> createState() => _RewardsMarketplaceScreenState();
}

class _RewardsMarketplaceScreenState extends State<RewardsMarketplaceScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMoreData = true;
  String? _selectedCategory;
  double? _maxCost;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    // Delay loading rewards until after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRewards();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !Provider.of<RewardsProviderSupabase>(context, listen: false).isLoading &&
          _hasMoreData) {
        _loadMoreRewards();
      }
    });
  }

  Future<void> _loadRewards() async {
    final rewardsProvider = Provider.of<RewardsProviderSupabase>(context, listen: false);

    try {
      await rewardsProvider.fetchAvailableRewards(
        category: _selectedCategory,
        maxServDRCost: _maxCost,
        page: 1,
        pageSize: 20,
        reset: true,
      );

      setState(() {
        _currentPage = 1;
        _hasMoreData = rewardsProvider.availableRewards.length >= 20;
      });
    } catch (e) {
      // Error handled in provider
    }
  }

  Future<void> _loadMoreRewards() async {
    if (Provider.of<RewardsProviderSupabase>(context, listen: false).isLoading) {
      return;
    }

    final rewardsProvider = Provider.of<RewardsProviderSupabase>(context, listen: false);

    try {
      final nextPage = _currentPage + 1;

      await rewardsProvider.fetchAvailableRewards(
        category: _selectedCategory,
        maxServDRCost: _maxCost,
        page: nextPage,
        pageSize: 20,
        reset: false,
      );

      final rewardsCount = rewardsProvider.availableRewards.length;

      setState(() {
        _currentPage = nextPage;
        _hasMoreData = rewardsCount >= nextPage * 20;
      });
    } catch (e) {
      // Error handled in provider
    }
  }

  Future<void> _refreshRewards() async {
    await _loadRewards();
  }

  void _applyFilters({String? category, double? maxCost}) {
    setState(() {
      _selectedCategory = category;
      _maxCost = maxCost;
    });

    _loadRewards();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _maxCost = null;
    });

    _loadRewards();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tempCategory = _selectedCategory;
        double? tempMaxCost = _maxCost;

        return AlertDialog(
          title: const Text('Filter Rewards'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category filter
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: tempCategory == null,
                      onSelected: (selected) {
                        if (selected) {
                          tempCategory = null;
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('Retail'),
                      selected: tempCategory == 'Retail',
                      onSelected: (selected) {
                        if (selected) {
                          tempCategory = 'Retail';
                        } else if (tempCategory == 'Retail') {
                          tempCategory = null;
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('Dining'),
                      selected: tempCategory == 'Dining',
                      onSelected: (selected) {
                        if (selected) {
                          tempCategory = 'Dining';
                        } else if (tempCategory == 'Dining') {
                          tempCategory = null;
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('Entertainment'),
                      selected: tempCategory == 'Entertainment',
                      onSelected: (selected) {
                        if (selected) {
                          tempCategory = 'Entertainment';
                        } else if (tempCategory == 'Entertainment') {
                          tempCategory = null;
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('Gift Cards'),
                      selected: tempCategory == 'Gift Cards',
                      onSelected: (selected) {
                        if (selected) {
                          tempCategory = 'Gift Cards';
                        } else if (tempCategory == 'Gift Cards') {
                          tempCategory = null;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Max cost filter
                const Text(
                  'Maximum Cost',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Any'),
                      selected: tempMaxCost == null,
                      onSelected: (selected) {
                        if (selected) {
                          tempMaxCost = null;
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('5 SERV DR'),
                      selected: tempMaxCost == 5,
                      onSelected: (selected) {
                        if (selected) {
                          tempMaxCost = 5;
                        } else if (tempMaxCost == 5) {
                          tempMaxCost = null;
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('10 SERV DR'),
                      selected: tempMaxCost == 10,
                      onSelected: (selected) {
                        if (selected) {
                          tempMaxCost = 10;
                        } else if (tempMaxCost == 10) {
                          tempMaxCost = null;
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('20 SERV DR'),
                      selected: tempMaxCost == 20,
                      onSelected: (selected) {
                        if (selected) {
                          tempMaxCost = 20;
                        } else if (tempMaxCost == 20) {
                          tempMaxCost = null;
                        }
                      },
                    ),
                    FilterChip(
                      label: const Text('50 SERV DR'),
                      selected: tempMaxCost == 50,
                      onSelected: (selected) {
                        if (selected) {
                          tempMaxCost = 50;
                        } else if (tempMaxCost == 50) {
                          tempMaxCost = null;
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearFilters();
              },
              child: const Text('Clear All'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilters(
                  category: tempCategory,
                  maxCost: tempMaxCost,
                );
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToRewardDetail(String rewardId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RewardDetailScreen(rewardId: rewardId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Consumer2<RewardsProviderSupabase, AuthProvider>(
        builder: (context, rewardsProvider, authProvider, child) {
          final rewards = rewardsProvider.availableRewards;
          final wallet = rewardsProvider.wallet;
          final isLoading = rewardsProvider.isLoading;
          final errorMessage = rewardsProvider.errorMessage;

          if (isLoading && rewards.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null && rewards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $errorMessage',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshRewards,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Wallet balance card
              if (wallet != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Balance: ${wallet.servDRBalance.toStringAsFixed(2)} SERV DR',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

              // Active filters
              if (_selectedCategory != null || _maxCost != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_selectedCategory != null)
                        Chip(
                          label: Text('Category: $_selectedCategory'),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _selectedCategory = null;
                            });
                            _loadRewards();
                          },
                        ),
                      if (_maxCost != null)
                        Chip(
                          label: Text('Max: $_maxCost SERV DR'),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _maxCost = null;
                            });
                            _loadRewards();
                          },
                        ),
                      if (_selectedCategory != null || _maxCost != null)
                        ActionChip(
                          label: const Text('Clear All'),
                          onPressed: _clearFilters,
                        ),
                    ],
                  ),
                ),

              // Rewards grid
              Expanded(
                child: rewards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.card_giftcard,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedCategory != null || _maxCost != null
                                  ? 'No rewards match your filters'
                                  : 'No rewards available',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            if (_selectedCategory != null || _maxCost != null) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _clearFilters,
                                child: const Text('Clear Filters'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshRewards,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: rewards.length + (isLoading && _hasMoreData ? 2 : 0),
                          itemBuilder: (context, index) {
                            // Loading indicators at the bottom
                            if (index >= rewards.length) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final reward = rewards[index];
                            return RewardCard(
                              reward: reward,
                              onTap: () => _navigateToRewardDetail(reward.id),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

