import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/providers/user_provider.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';

class ServiceHistoryList extends StatefulWidget {
  const ServiceHistoryList({Key? key}) : super(key: key);

  @override
  State<ServiceHistoryList> createState() => _ServiceHistoryListState();
}

class _ServiceHistoryListState extends State<ServiceHistoryList> {
  final List<Map<String, dynamic>> _historyItems = [
    {
      'id': '1',
      'projectName': 'Beach Cleanup',
      'date': DateTime(2023, 3, 15),
      'hours': 4.5,
      'points': 450,
      'status': 'Verified',
    },
    {
      'id': '2',
      'projectName': 'Food Bank',
      'date': DateTime(2023, 2, 20),
      'hours': 3.0,
      'points': 300,
      'status': 'Verified',
    },
    {
      'id': '3',
      'projectName': 'Habitat Build',
      'date': DateTime(2023, 1, 10),
      'hours': 6.0,
      'points': 600,
      'status': 'Verified',
    },
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchServiceHistory();
  }

  Future<void> _fetchServiceHistory() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // TODO: Replace mock data with actual service history
      // final historyData = await userProvider.getServiceHistory(page: 1, pageSize: 5);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_historyItems.isEmpty) {
      return const Center(
        child: Text('No service history available'),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _historyItems.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = _historyItems[index];
        final date = DateFormat.yMMMd().format(item['date']);
        
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.history,
              color: AppTheme.primaryColor,
            ),
          ),
          title: Text(item['projectName']),
          subtitle: Text('$date • ${item['hours']} hours'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item['points']} points',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
              Text(
                item['status'],
                style: TextStyle(
                  fontSize: 12,
                  color: item['status'] == 'Verified'
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
                ),
              ),
            ],
          ),
          onTap: () {
            // Navigate to service details
          },
        );
      },
    );
  }
}
