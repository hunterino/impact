import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/service_opportunities/models/project_slot_model.dart';

class ProjectSlotCard extends StatelessWidget {
  final ProjectSlotModel slot;
  final VoidCallback onRegister;
  
  const ProjectSlotCard({
    Key? key,
    required this.slot,
    required this.onRegister,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Text(
              DateFormat.yMMMMEEEEd().format(slot.startTime),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Time
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat.jm().format(slot.startTime)} - ${DateFormat.jm().format(slot.endTime)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${slot.durationHours} hours)',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryDarkColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Capacity
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '${slot.currentVolunteers}/${slot.maxCapacity} volunteers',
                  style: TextStyle(
                    fontSize: 14,
                    color: slot.isAtCapacity
                        ? Colors.red
                        : AppTheme.textSecondaryDarkColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Status and Register button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(slot.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    slot.status,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(slot.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Register button
                ElevatedButton(
                  onPressed: slot.isAtCapacity ? null : onRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    slot.isAtCapacity ? 'Full' : 'Register',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.successColor;
      case 'filling':
        return AppTheme.infoColor;
      case 'full':
        return AppTheme.errorColor;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.grey;
      default:
        return AppTheme.infoColor;
    }
  }
}
