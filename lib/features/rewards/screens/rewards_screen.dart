import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/rewards/screens/rewards_marketplace_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({Key? key}) : super(key: key);

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Marketplace'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          const RewardsMarketplaceScreen(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points balance card
          _buildBalanceCard(),
          const SizedBox(height: 20),

          // Quick actions
          _buildQuickActions(),
          const SizedBox(height: 20),

          // Points breakdown
          _buildPointsBreakdown(),
          const SizedBox(height: 20),

          // Recent rewards
          _buildRecentRewards(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Balance',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          '2,450',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'STBF Points',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+150 this month',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.account_balance_wallet,
                  size: 64,
                  color: Colors.white.withOpacity(0.3),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBalanceInfo(
                  label: 'ServDr',
                  value: '245',
                  icon: Icons.monetization_on,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white24,
                ),
                _buildBalanceInfo(
                  label: 'Pending',
                  value: '50',
                  icon: Icons.schedule,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white24,
                ),
                _buildBalanceInfo(
                  label: 'Lifetime',
                  value: '5.2K',
                  icon: Icons.emoji_events,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceInfo({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.swap_horiz,
                title: 'Convert',
                subtitle: 'Points to ServDr',
                color: Colors.blue,
                onTap: () {
                  // Navigate to conversion
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.card_giftcard,
                title: 'Redeem',
                subtitle: 'Get rewards',
                color: Colors.green,
                onTap: () {
                  _tabController.animateTo(1);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.history,
                title: 'History',
                subtitle: 'View transactions',
                color: Colors.orange,
                onTap: () {
                  _tabController.animateTo(2);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.info,
                title: 'Learn',
                subtitle: 'How it works',
                color: Colors.purple,
                onTap: () {
                  // Show info
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Points Breakdown',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildBreakdownItem(
                'Service Hours',
                1200,
                0.49,
                Icons.access_time,
                Colors.blue,
              ),
              const Divider(height: 1),
              _buildBreakdownItem(
                'Project Completion',
                800,
                0.33,
                Icons.check_circle,
                Colors.green,
              ),
              const Divider(height: 1),
              _buildBreakdownItem(
                'Team Activities',
                300,
                0.12,
                Icons.group,
                Colors.orange,
              ),
              const Divider(height: 1),
              _buildBreakdownItem(
                'Achievements',
                150,
                0.06,
                Icons.emoji_events,
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(
    String category,
    int points,
    double percentage,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRewards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Rewards',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                _tabController.animateTo(2);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRewardItem(
          title: 'Coffee Shop Voucher',
          merchant: 'Local Coffee Co.',
          date: '2 days ago',
          points: 150,
          icon: Icons.local_cafe,
          color: Colors.brown,
        ),
        const SizedBox(height: 8),
        _buildRewardItem(
          title: 'Movie Ticket',
          merchant: 'CineMax',
          date: '1 week ago',
          points: 300,
          icon: Icons.movie,
          color: Colors.red,
        ),
        const SizedBox(height: 8),
        _buildRewardItem(
          title: 'Bookstore Discount',
          merchant: 'ReadMore Books',
          date: '2 weeks ago',
          points: 100,
          icon: Icons.book,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildRewardItem({
    required String title,
    required String merchant,
    required String date,
    required int points,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title),
        subtitle: Text('$merchant • $date'),
        trailing: Text(
          '-$points pts',
          style: TextStyle(
            color: Colors.red[400],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 15,
      itemBuilder: (context, index) {
        if (index % 4 == 0) {
          return _buildTransactionItem(
            title: 'Volunteer at Food Bank',
            subtitle: '3 hours • Service',
            points: 30,
            isEarned: true,
            date: '${15 - index} days ago',
            icon: Icons.volunteer_activism,
            color: Colors.green,
          );
        } else if (index % 4 == 1) {
          return _buildTransactionItem(
            title: 'Coffee Voucher Redeemed',
            subtitle: 'Local Coffee Co.',
            points: 150,
            isEarned: false,
            date: '${15 - index} days ago',
            icon: Icons.local_cafe,
            color: Colors.brown,
          );
        } else if (index % 4 == 2) {
          return _buildTransactionItem(
            title: 'Project Completion Bonus',
            subtitle: 'Beach Cleanup',
            points: 50,
            isEarned: true,
            date: '${15 - index} days ago',
            icon: Icons.check_circle,
            color: Colors.blue,
          );
        } else {
          return _buildTransactionItem(
            title: 'Converted to ServDr',
            subtitle: 'Currency Exchange',
            points: 100,
            isEarned: false,
            date: '${15 - index} days ago',
            icon: Icons.swap_horiz,
            color: Colors.orange,
          );
        }
      },
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String subtitle,
    required int points,
    required bool isEarned,
    required String date,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title),
        subtitle: Text('$subtitle • $date'),
        trailing: Text(
          '${isEarned ? '+' : '-'}$points pts',
          style: TextStyle(
            color: isEarned ? Colors.green : Colors.red[400],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}