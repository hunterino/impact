import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/providers/project_provider.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';

import '../models/project_model.dart';
import '../models/project_slot_model.dart';

class ProjectRegistrationScreen extends StatefulWidget {
  final String projectId;
  final String? slotId;

  const ProjectRegistrationScreen({
    Key? key,
    required this.projectId,
    this.slotId,
  }) : super(key: key);

  @override
  State<ProjectRegistrationScreen> createState() => _ProjectRegistrationScreenState();
}

class _ProjectRegistrationScreenState extends State<ProjectRegistrationScreen> {
  int _numberOfVolunteers = 1;
  bool _addToCalendar = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _registrationComplete = false;

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final project = projectProvider.currentProject;

    if (project == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Find the slot if slotId is provided
    final slot = widget.slotId != null
        ? projectProvider.currentProjectSlots.firstWhere(
            (s) => s.id == widget.slotId,
            orElse: () => throw Exception('Slot not found'),
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
        elevation: 0,
      ),
      body: _registrationComplete
          ? _buildRegistrationComplete(project, slot)
          : _buildRegistrationForm(project, slot, authProvider),
    );
  }

  Widget _buildRegistrationForm(
    ProjectModel project,
    ProjectSlotModel? slot,
    AuthProvider authProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppTheme.textSecondaryDarkColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          project.location,
                          style: const TextStyle(
                            color: AppTheme.textSecondaryDarkColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppTheme.textSecondaryDarkColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        slot != null
                            ? '${DateFormat.yMMMd().format(slot.startTime)} • ${DateFormat.jm().format(slot.startTime)} - ${DateFormat.jm().format(slot.endTime)}'
                            : '${DateFormat.yMMMd().format(project.startDate)} • ${DateFormat.jm().format(project.startDate)} - ${DateFormat.jm().format(project.endDate)}',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryDarkColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Registration Form
          const Text(
            'Registration Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Number of Volunteers
          Row(
            children: [
              const Text('Number of Volunteers:'),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _numberOfVolunteers > 1
                          ? () {
                              setState(() {
                                _numberOfVolunteers--;
                              });
                            }
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$_numberOfVolunteers',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _numberOfVolunteers < 5
                          ? () {
                              setState(() {
                                _numberOfVolunteers++;
                              });
                            }
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Add to Calendar
          Row(
            children: [
              const Text('Add to Calendar:'),
              const Spacer(),
              Switch(
                value: _addToCalendar,
                onChanged: (value) {
                  setState(() {
                    _addToCalendar = value;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Terms and Requirements
          const Text(
            'Requirements & Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (project.requiredSkills.isNotEmpty) ...[
            const Text(
              'Required Skills:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: project.requiredSkills.map((skill) => Chip(
                label: Text(skill),
                backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                labelStyle: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 12,
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'By registering, you agree to:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.check_circle, color: AppTheme.successColor),
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 20,
            title: Text('Arrive on time and stay for the full duration'),
          ),
          const ListTile(
            leading: Icon(Icons.check_circle, color: AppTheme.successColor),
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 20,
            title: Text('Follow all safety guidelines and instructions'),
          ),
          const ListTile(
            leading: Icon(Icons.check_circle, color: AppTheme.successColor),
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 20,
            title: Text('Cancel at least 24 hours in advance if unable to attend'),
          ),
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppTheme.errorColor,
                ),
              ),
            ),

          // Register Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _registerForProject(authProvider.user?.id ?? ''),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Complete Registration'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationComplete(
    ProjectModel project,
    ProjectSlotModel? slot,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Registration Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You have successfully registered for ${project.title}',
              style: const TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              slot != null
                  ? '${DateFormat.yMMMd().format(slot.startTime)} • ${DateFormat.jm().format(slot.startTime)} - ${DateFormat.jm().format(slot.endTime)}'
                  : '${DateFormat.yMMMd().format(project.startDate)} • ${DateFormat.jm().format(project.startDate)} - ${DateFormat.jm().format(project.endDate)}',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryDarkColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Thank you for volunteering! You will receive a confirmation email with more details.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () {
                // Navigate back to project listing
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst || route.settings.name == '/projects',
                );
              },
              child: const Text('Find More Projects'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Back to project details
                Navigator.pop(context);
              },
              child: const Text('Back to Project Details'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerForProject(String userId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      final success = await projectProvider.registerForProject(
        userId,
        widget.projectId,
        widget.slotId,
        _numberOfVolunteers,
      );

      if (success) {
        // Add to calendar if selected
        if (_addToCalendar) {
          // TODO: Implement calendar integration
        }

        setState(() {
          _isLoading = false;
          _registrationComplete = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }
}
