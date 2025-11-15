import 'package:flutter/material.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/rewards/models/reward_model.dart';

class RewardCard extends StatelessWidget {
  final RewardModel reward;
  final VoidCallback onTap;
  
  const RewardCard({
    Key? key,
    required this.reward,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: reward.isAvailable ? onTap : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reward Image
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: reward.imageUrl != null
                      ? Image.network(
                          reward.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppTheme.surfaceDarkColor,
                          child: const Icon(
                            Icons.card_giftcard,
                            size: 48,
                            color: AppTheme.textSecondaryDarkColor,
                          ),
                        ),
                ),
                if (!reward.isAvailable)
                  Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          reward.isOutOfStock
                              ? 'OUT OF STOCK'
                              : 'UNAVAILABLE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Merchant Logo - commented out since we don't have logo URLs
                // if (reward.vendorName != null)
                //   Positioned(
                //     top: 8,
                //     left: 8,
                //     child: Container(
                //       width: 32,
                //       height: 32,
                //       decoration: BoxDecoration(
                //         color: Colors.white,
                //         shape: BoxShape.circle,
                //         boxShadow: [
                //           BoxShadow(
                //             color: Colors.black.withOpacity(0.2),
                //             blurRadius: 4,
                //             offset: const Offset(0, 2),
                //           ),
                //         ],
                //       ),
                //       padding: const EdgeInsets.all(2),
                //     ),
                //   ),
              ],
            ),
            
            // Reward Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (reward.vendorName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      reward.vendorName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryDarkColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.token,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reward.servDRCost} SERV DR',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
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
