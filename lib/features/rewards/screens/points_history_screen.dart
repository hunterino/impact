import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/services/rewards_service.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/rewards/widgets/points_transaction_tile.dart';

class PointsHistoryScreen extends StatefulWidget {
  const PointsHistoryScreen({super.key});

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _setupScrollListener();
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
          !Provider.of<RewardsProvider>(context, listen: false).isLoading &&
          _hasMoreData) {
        _loadMoreTransactions();
      }
    });
  }

  Future<void> _loadTransactions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);

    if (authProvider.user != null) {
      try {
        await rewardsProvider.fetchPointsTransactions(
          authProvider.user!.id,
          page: 1,
          pageSize: 20,
          reset: true,
        );

        setState(() {
          _currentPage = 1;
          _hasMoreData = rewardsProvider.pointsTransactions.length >= 20;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (Provider.of<RewardsProvider>(context, listen: false).isLoading) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rewardsProvider = Provider.of<RewardsProvider>(context, listen: false);

    if (authProvider.user != null) {
      try {
        final nextPage = _currentPage + 1;

        await rewardsProvider.fetchPointsTransactions(
          authProvider.user!.id,
          page: nextPage,
          pageSize: 20,
          reset: false,
        );

        final transactionsCount = rewardsProvider.pointsTransactions.length;

        setState(() {
          _currentPage = nextPage;
          _hasMoreData = transactionsCount >= nextPage * 20;
        });
      } catch (e) {
        // Error already handled in provider
      }
    }
  }

  Future<void> _refreshTransactions() async {
    await _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points History'),
      ),
      body: Consumer<RewardsProvider>(
        builder: (context, rewardsProvider, child) {
          final transactions = rewardsProvider.pointsTransactions;
          final isLoading = rewardsProvider.isLoading;
          final errorMessage = rewardsProvider.errorMessage;

          if (isLoading && transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null && transactions.isEmpty) {
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
                    onPressed: _refreshTransactions,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No transaction history yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Earn points by completing service projects',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Wallet balance card
              if (rewardsProvider.wallet != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Column(
                    children: [
                      const Text(
                        'Current Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryDarkColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${rewardsProvider.wallet!.stbfPointsBalance}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Points expiring soon: ${rewardsProvider.wallet!.stbfPointsExpiringSoon}',
                        style: TextStyle(
                          fontSize: 12,
                          color: rewardsProvider.wallet!.stbfPointsExpiringSoon > 0
                              ? AppTheme.warningColor
                              : AppTheme.textSecondaryDarkColor,
                        ),
                      ),
                    ],
                  ),
                ),

              // Transactions list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshTransactions,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: transactions.length + (isLoading && _hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Loading indicator at the bottom
                      if (index == transactions.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final transaction = transactions[index];
                      return PointsTransactionTile(transaction: transaction);
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
