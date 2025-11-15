import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/services/volunteer_service.dart';
import 'package:serve_to_be_free/core/providers/project_provider.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';

class LogHoursScreen extends StatefulWidget {
  final String projectId;
  final String? slotId;
  final DateTime? serviceDate;
  
  const LogHoursScreen({
    Key? key,
    required this.projectId,
    this.slotId,
    this.serviceDate,
  }) : super(key: key);

  @override
  State<LogHoursScreen> createState() => _LogHoursScreenState();
}

class _LogHoursScreenState extends State<LogHoursScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _serviceDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late double _hoursServed;
  final List<String> _selectedSkills = [];
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _logComplete = false;
  
  @override
  void initState() {
    super.initState();
    _serviceDate = widget.serviceDate ?? DateTime.now();
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(
      hour: _startTime.hour + 3,
      minute: _startTime.minute,
    );
    _calculateHours();
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  void _calculateHours() {
    final start = DateTime(
      _serviceDate.year,
      _serviceDate.month,
      _serviceDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    
    final end = DateTime(
      _serviceDate.year,
      _serviceDate.month,
      _serviceDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    
    final difference = end.difference(start).inMinutes;
    _hoursServed = difference / 60.0;
    
    // Round to nearest quarter hour
    _hoursServed = ((_hoursServed * 4).round() / 4);
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _serviceDate) {
      setState(() {
        _serviceDate = picked;
        _calculateHours();
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _calculateHours();
      });
    }
  }
  
  Future<void> _logHours() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validate end time is after start time
    if (_hoursServed <= 0) {
      setState(() {
        _errorMessage = 'End time must be after start time';
      });
      return;
    }
    
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
      
      final startDateTime = DateTime(
        _serviceDate.year,
        _serviceDate.month,
        _serviceDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endDateTime = DateTime(
        _serviceDate.year,
        _serviceDate.month,
        _serviceDate.day,
        _endTime.hour,
        _endTime.minute,
      );
      
      await volunteerProvider.logServiceHours(
        authProvider.user!.id,
        widget.projectId,
        widget.slotId,
        _serviceDate,
        startDateTime,
        endDateTime,
        _hoursServed,
        _selectedSkills.isEmpty ? null : _selectedSkills,
        _notesController.text.isEmpty ? null : _notesController.text.trim(),
      );
      
      setState(() {
        _isLoading = false;
        _logComplete = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final project = projectProvider.currentProject;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Service Hours'),
      ),
      body: _logComplete
          ? _buildSuccessScreen()
          : _buildLogForm(project),
    );
  }
  
  Widget _buildLogForm(final project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Info
            if (project != null)
              Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 18,
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
                    ],
                  ),
                ),
              ),
            
            // Error message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
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
            
            // Service Date
            const Text(
              'Date of Service',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDarkColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat.yMMMMd().format(_serviceDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Start and End Time
            const Text(
              'Service Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDarkColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 12),
                          Text(
                            'Start: ${_startTime.format(context)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDarkColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 12),
                          Text(
                            'End: ${_endTime.format(context)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Total Hours
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.timer,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Total Hours: $_hoursServed',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Skills Used
            if (project != null && project.requiredSkills.isNotEmpty) ...[
              const Text(
                'Skills Used',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select all skills that you used during this service:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryDarkColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: project.requiredSkills.map((skill) {
                  final isSelected = _selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSkills.add(skill);
                        } else {
                          _selectedSkills.remove(skill);
                        }
                      });
                    },
                    backgroundColor: Colors.grey[800],
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            
            // Notes
            const Text(
              'Notes (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add any notes about your service...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _logHours,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Submit Hours'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuccessScreen() {
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
              'Hours Logged Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You have logged $_hoursServed hours of service on ${DateFormat.yMMMMd().format(_serviceDate)}',
              style: const TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your hours will be reviewed and verified by the project manager.',
              style: TextStyle(
                color: AppTheme.textSecondaryDarkColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
