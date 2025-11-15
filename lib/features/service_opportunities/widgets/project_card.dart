import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/service_opportunities/models/project_model.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final bool isFeatured;
  final VoidCallback onTap;
  
  const ProjectCard({
    Key? key,
    required this.project,
    this.isFeatured = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: isFeatured ? 4 : 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Image
            Stack(
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: project.imageUrls != null && project.imageUrls!.isNotEmpty
                      ? Image.network(
                          project.imageUrls!.first,
                          fit: BoxFit.cover,
                        )
                      : Container(
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
                if (isFeatured)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (project.isAtCapacity)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.6),
                      child: const Center(
                        child: Text(
                          'FULL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Project Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Title
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.textSecondaryDarkColor,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          project.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryDarkColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Date
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppTheme.textSecondaryDarkColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        project.isRecurring
                            ? '${project.recurringPattern} • Starting ${DateFormat.yMMMd().format(project.startDate)}'
                            : DateFormat.yMMMd().format(project.startDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryDarkColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Capacity
                  LinearProgressIndicator(
                    value: project.maxVolunteers > 0
                        ? project.currentVolunteers / project.maxVolunteers
                        : 0,
                    backgroundColor: Colors.grey[700],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      project.isAtCapacity
                          ? Colors.red
                          : AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${project.currentVolunteers}/${project.maxVolunteers} volunteers',
                    style: TextStyle(
                      fontSize: 12,
                      color: project.isAtCapacity
                          ? Colors.red
                          : AppTheme.textSecondaryDarkColor,
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
