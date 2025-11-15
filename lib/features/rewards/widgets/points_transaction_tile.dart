import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/rewards/models/points_transaction_model.dart';

class PointsTransactionTile extends StatelessWidget {
  final PointsTransactionModel transaction;
  
  const PointsTransactionTile({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isEarning = transaction.points > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Transaction icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isEarning
                    ? AppTheme.successColor.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEarning ? Icons.add_circle : Icons.swap_horiz,
                color: isEarning ? AppTheme.successColor : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTransactionTitle(transaction),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat.yMMMd().add_jm().format(transaction.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryDarkColor,
                    ),
                  ),
                  if (transaction.expirationDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Expires: ${DateFormat.yMMMd().format(transaction.expirationDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isExpiringSoon(transaction.expirationDate!)
                            ? AppTheme.warningColor
                            : AppTheme.textSecondaryDarkColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Points amount
            Text(
              isEarning ? '+${transaction.points}' : '${transaction.points}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isEarning ? AppTheme.successColor : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getTransactionTitle(PointsTransactionModel transaction) {
    switch (transaction.transactionType) {
      case 'service_completion':
        return 'Service Completion';
      case 'conversion':
        return 'Converted to SERV DR';
      case 'bonus':
        return 'Bonus Points';
      case 'expiration':
        return 'Points Expired';
      case 'adjustment':
        return 'Points Adjustment';
      default:
        return transaction.description ?? 'Transaction';
    }
  }
  
  bool _isExpiringSoon(DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now).inDays;
    return difference <= 30 && difference >= 0;
  }
}
