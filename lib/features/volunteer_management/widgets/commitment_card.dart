import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/volunteer_management/models/commitment_model.dart';

class CommitmentCard extends StatelessWidget {
  final CommitmentModel commitment;
  final bool isPast;
  final VoidCallback? onCancel;
  final VoidCallback? onLogHours;
  
  const CommitmentCard({
    Key? key,
    required this.commitment,
    this.isPast = false,
    this.onCancel,
    this.onLogHours,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Image or Header
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: commitment.projectImageUrl != null
                ? Image.network(
                    commitment.projectImageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 80,
                    width: double.infinity,
                    color: AppTheme.primaryColor,
                    child: Center(
                      child: Icon(
                        Icons.volunteer_activism,
                        size: 40,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
          ),
          
          // Project Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Title
                Text(
                  commitment.projectTitle,
                  style: const TextStyle(
                    fontSize: 18,
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
                      DateFormat.yMMMMEEEEd().format(commitment.commitmentDate),
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
                      '${DateFormat.jm().format(commitment.startTime)} - ${DateFormat.jm().format(commitment.endTime)}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                // Number of Volunteers
                if (commitment.numberOfVolunteers > 1) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${commitment.numberOfVolunteers} volunteers registered',
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Status Chip
                Chip(
                  label: Text(commitment.status),
                  backgroundColor: _getStatusColor(commitment.status).withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: _getStatusColor(commitment.status),
                    fontSize: 12,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isPast && onLogHours != null && commitment.isCompleted)
                      ElevatedButton(
                        onPressed: onLogHours,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                        ),
                        child: const Text('Log Hours'),
                      ),
                    if (!isPast && onCancel != null)
                      TextButton(
                        onPressed: onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                        ),
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'cancelled':
        return AppTheme.errorColor;
      case 'completed':
        return AppTheme.infoColor;
      default:
        return AppTheme.primaryColor;
    }
  }
}
