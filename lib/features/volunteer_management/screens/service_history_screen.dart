import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/services/volunteer_service.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/volunteer_management/widgets/service_record_card.dart';
import 'package:serve_to_be_free/features/volunteer_management/screens/service_detail_screen.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  void initState() {
    super.initState();
    _loadServiceHistory();
  }
  
  Future<void> _loadServiceHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await volunteerProvider.fetchServiceHistory(
        authProvider.user!.id,
        startDate: _startDate,
        endDate: _endDate,
      );
    }
  }
  
  Future<void> _refreshData() async {
    await _loadServiceHistory();
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      
      await _loadServiceHistory();
    }
  }
  
  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    
    _loadServiceHistory();
  }
  
  void _navigateToServiceDetail(String recordId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailScreen(recordId: recordId),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Filter by Date',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date filter chip
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Chip(
                label: Text(
                  '${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}',
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: _clearDateFilter,
              ),
            ),
          
          // Service records list
          Expanded(
            child: Consumer<VolunteerProvider>(
              builder: (context, volunteerProvider, child) {
                if (volunteerProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (volunteerProvider.serviceHistory.isEmpty) {
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
                          'No service history found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_startDate != null && _endDate != null)
                          TextButton(
                            onPressed: _clearDateFilter,
                            child: const Text('Clear Date Filter'),
                          ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: volunteerProvider.serviceHistory.length,
                    itemBuilder: (context, index) {
                      final record = volunteerProvider.serviceHistory[index];
                      return ServiceRecordCard(
                        record: record,
                        onTap: () => _navigateToServiceDetail(record.id),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          
          // Stats summary card
          Consumer<VolunteerProvider>(
            builder: (context, volunteerProvider, child) {
              final history = volunteerProvider.serviceHistory;
              if (history.isEmpty) {
                return const SizedBox.shrink();
              }
              
              double totalHours = 0;
              int totalPoints = 0;
              
              for (final record in history) {
                if (record.status == 'Verified') {
                  totalHours += record.hoursServed;
                  totalPoints += record.pointsEarned;
                }
              }
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDarkColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          totalHours.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const Text('Total Hours'),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          totalPoints.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const Text('Total Points'),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          history.length.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        const Text('Projects'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
