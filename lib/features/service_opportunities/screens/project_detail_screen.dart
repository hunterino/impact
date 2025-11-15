import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/providers/project_provider.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/service_opportunities/widgets/project_slot_card.dart';
import 'package:serve_to_be_free/features/service_opportunities/screens/project_registration_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  
  const ProjectDetailScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProjectDetails();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProjectDetails() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      projectProvider.fetchProjectDetails(widget.projectId);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final project = projectProvider.currentProject;
        final slots = projectProvider.currentProjectSlots;
        final isLoading = projectProvider.isLoading;
        
        return Scaffold(
          body: isLoading || project == null
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    // App Bar with Project Image
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          project.title,
                          style: const TextStyle(
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        background: project.imageUrls != null && project.imageUrls!.isNotEmpty
                            ? Image.network(
                                project.imageUrls!.first,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: AppTheme.primaryColor,
                                child: Center(
                                  child: Icon(
                                    Icons.volunteer_activism,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    
                    // Project Info
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Organizer Info
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: project.organizerImageUrl != null
                                      ? NetworkImage(project.organizerImageUrl!)
                                      : null,
                                  child: project.organizerImageUrl == null
                                      ? const Icon(Icons.person, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Organized by:',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      project.organizerName ?? 'Unknown Organizer',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Location
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    project.location,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Date & Time
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  project.isRecurring
                                      ? '${project.recurringPattern} • ${DateFormat.yMMMd().format(project.startDate)} to ${DateFormat.yMMMd().format(project.endDate)}'
                                      : '${DateFormat.yMMMd().format(project.startDate)} • ${DateFormat.jm().format(project.startDate)} - ${DateFormat.jm().format(project.endDate)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Volunteer capacity
                            Row(
                              children: [
                                const Icon(
                                  Icons.people_outline,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${project.currentVolunteers}/${project.maxVolunteers} volunteers registered',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const Spacer(),
                                if (project.pointsMultiplier != null && project.pointsMultiplier! > 1.0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: AppTheme.accentColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${project.pointsMultiplier!.toStringAsFixed(1)}x points',
                                          style: const TextStyle(
                                            color: AppTheme.accentColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Cause Areas & Tags
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...project.causeAreas.map((area) => Chip(
                                  label: Text(area),
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12,
                                  ),
                                )),
                                ...?project.tags?.map((tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: Colors.grey[800],
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                )),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Tab Bar
                            TabBar(
                              controller: _tabController,
                              labelColor: AppTheme.primaryColor,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: AppTheme.primaryColor,
                              tabs: const [
                                Tab(text: 'Details'),
                                Tab(text: 'Schedule'),
                                Tab(text: 'Volunteers'),
                                Tab(text: 'Updates'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Tab Content
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Details Tab
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'About this project',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  project.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Skills Needed',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                              ],
                            ),
                          ),
                          
                          // Schedule Tab
                          slots.isEmpty
                              ? const Center(
                                  child: Text('No schedule information available'),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: slots.length,
                                  itemBuilder: (context, index) {
                                    final slot = slots[index];
                                    return ProjectSlotCard(
                                      slot: slot,
                                      onRegister: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProjectRegistrationScreen(
                                              projectId: project.id,
                                              slotId: slot.id,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                          
                          // Volunteers Tab (Placeholder)
                          const Center(
                            child: Text('Volunteer list will be shown here'),
                          ),
                          
                          // Updates Tab (Placeholder)
                          const Center(
                            child: Text('Project updates will be shown here'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: isLoading || project == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: project.isAtCapacity
                          ? null
                          : () {
                              // For recurring projects with multiple slots
                              if (project.isRecurring && slots.isNotEmpty) {
                                _tabController.animateTo(1); // Switch to schedule tab
                              } else {
                                // For single-time projects
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProjectRegistrationScreen(
                                      projectId: project.id,
                                    ),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.grey[700],
                        disabledForegroundColor: Colors.white70,
                      ),
                      child: Text(
                        project.isAtCapacity
                            ? 'Project at Capacity'
                            : project.isRecurring && slots.isNotEmpty
                                ? 'View Available Slots'
                                : 'Register Now',
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
