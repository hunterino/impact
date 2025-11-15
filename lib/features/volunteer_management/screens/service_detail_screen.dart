import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/services/volunteer_service.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/volunteer_management/models/service_record_model.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String recordId;

  const ServiceDetailScreen({
    Key? key,
    required this.recordId,
  }) : super(key: key);

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  ServiceRecordModel? _serviceRecord;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadServiceRecord();
  }

  Future<void> _loadServiceRecord() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final volunteerProvider = Provider.of<VolunteerProvider>(context, listen: false);

      if (authProvider.user == null) {
        throw Exception('User not authenticated');
      }

      // Find the record in existing history first
      final recordFromCache = volunteerProvider.serviceHistory.firstWhere(
        (record) => record.id == widget.recordId,
        orElse: () => throw Exception('Service record not found'),
      );

      // Load full details from the API
      await volunteerProvider.fetchServiceHistory(authProvider.user!.id);

      setState(() {
        _serviceRecord = volunteerProvider.serviceHistory.firstWhere(
          (record) => record.id == widget.recordId,
          orElse: () => recordFromCache,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $_errorMessage',
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadServiceRecord,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _serviceRecord == null
                  ? const Center(child: Text('Service record not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Project Info Card
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Project Image
                                if (_serviceRecord!.projectImageUrl != null)
                                  Image.network(
                                    _serviceRecord!.projectImageUrl!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),

                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _serviceRecord!.projectTitle,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Date and Time
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: AppTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat.yMMMMd().format(_serviceRecord!.serviceDate),
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: AppTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${DateFormat.jm().format(_serviceRecord!.startTime)} - ${DateFormat.jm().format(_serviceRecord!.endTime)}',
                                            style: const TextStyle(
                                              fontSize: 14,
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
                          const SizedBox(height: 24),

                          // Service Stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Hours',
                                  _serviceRecord!.hoursServed.toStringAsFixed(1),
                                  Icons.access_time,
                                  AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Points',
                                  _serviceRecord!.pointsEarned.toString(),
                                  Icons.star,
                                  AppTheme.accentColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_serviceRecord!.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor(_serviceRecord!.status),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getStatusIcon(_serviceRecord!.status),
                                  color: _getStatusColor(_serviceRecord!.status),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status: ${_serviceRecord!.status}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(_serviceRecord!.status),
                                      ),
                                    ),
                                    if (_serviceRecord!.verifiedBy != null && _serviceRecord!.verifiedAt != null)
                                      Text(
                                        'Verified by ${_serviceRecord!.verifiedBy} on ${DateFormat.yMMMd().format(_serviceRecord!.verifiedAt!)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Skills Section
                          if (_serviceRecord!.skills != null && _serviceRecord!.skills!.isNotEmpty) ...[
                            const Text(
                              'Skills Used',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _serviceRecord!.skills!.map((skill) => Chip(
                                label: Text(skill),
                                backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                                labelStyle: const TextStyle(
                                  color: AppTheme.secondaryColor,
                                ),
                              )).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Notes Section
                          if (_serviceRecord!.notes != null && _serviceRecord!.notes!.isNotEmpty) ...[
                            const Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDarkColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(_serviceRecord!.notes!),
                            ),
                          ],

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'rejected':
        return AppTheme.errorColor;
      default:
        return AppTheme.infoColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Icons.verified;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
