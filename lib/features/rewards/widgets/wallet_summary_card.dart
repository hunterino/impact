import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/rewards/models/wallet_model.dart';

class WalletSummaryCard extends StatelessWidget {
  final WalletModel wallet;
  final VoidCallback? onPointsHistoryTap;
  final VoidCallback? onServDRHistoryTap;

  const WalletSummaryCard({
    super.key,
    required this.wallet,
    this.onPointsHistoryTap,
    this.onServDRHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Wallet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // STBF Points
            InkWell(
              onTap: onPointsHistoryTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: AppTheme.primaryColor,
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STBF Points',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryDarkColor,
                            ),
                          ),
                          Text(
                            '${wallet.stbfPointsBalance}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),

            if (wallet.stbfPointsExpiringSoon > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.warningColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${wallet.stbfPointsExpiringSoon} points expiring on ${DateFormat.yMMMd().format(wallet.nextExpirationDate!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // SERV DR
            InkWell(
              onTap: onServDRHistoryTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.token,
                      color: AppTheme.accentColor,
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SERV DR',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryDarkColor,
                            ),
                          ),
                          Text(
                            wallet.servDRBalance.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppTheme.accentColor,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // SERV Coin
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: wallet.servCoinWalletActivated
                    ? AppTheme.secondaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: wallet.servCoinWalletActivated
                        ? AppTheme.secondaryColor
                        : Colors.grey,
                    size: 36,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SERV Coin',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryDarkColor,
                          ),
                        ),
                        wallet.servCoinWalletActivated
                            ? Text(
                                wallet.servCoinBalance.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Text(
                                'Not activated',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                      ],
                    ),
                  ),
                  if (wallet.servCoinWalletActivated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
