import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:serve_to_be_free/core/providers/project_provider.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/service_opportunities/models/project_model.dart';
import 'package:serve_to_be_free/features/service_opportunities/screens/project_detail_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // Filter states
  String? _selectedCauseArea;
  String? _selectedStatus;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProjects() {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    projectProvider.fetchFeaturedProjects();
    projectProvider.searchProjects();
    projectProvider.fetchCauseAreas();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      projectProvider.loadMoreSearchResults(
        query: _searchController.text.isEmpty ? null : _searchController.text,
        causeAreas: _selectedCauseArea != null ? [_selectedCauseArea!] : null,
        status: _selectedStatus,
      );
    }
  }

  void _performSearch() {
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    projectProvider.searchProjects(
      query: _searchController.text.isEmpty ? null : _searchController.text,
      causeAreas: _selectedCauseArea != null ? [_selectedCauseArea!] : null,
      status: _selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Opportunities'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadProjects();
        },
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(),

            // Filters section (collapsible)
            if (_showFilters)
              _buildFilters(),

            // Projects list
            Expanded(
              child: Consumer<ProjectProvider>(
                builder: (context, projectProvider, _) {
                  if (projectProvider.isLoading &&
                      projectProvider.searchResults.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (projectProvider.searchResults.isEmpty &&
                      projectProvider.featuredProjects.isEmpty) {
                    return _buildEmptyState();
                  }

                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Featured projects section
                      if (projectProvider.featuredProjects.isNotEmpty)
                        _buildFeaturedSection(projectProvider.featuredProjects),

                      // All projects list
                      _buildProjectsList(projectProvider),

                      // Loading indicator for pagination
                      if (projectProvider.isLoading &&
                          projectProvider.searchResults.isNotEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search projects...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _performSearch(),
      ),
    );
  }

  Widget _buildFilters() {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Cause area filter
              Row(
                children: [
                  const Text('Cause: '),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String?>(
                      value: _selectedCauseArea,
                      isExpanded: true,
                      hint: const Text('All Causes'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Causes'),
                        ),
                        ...projectProvider.causeAreas.map((cause) {
                          return DropdownMenuItem(
                            value: cause,
                            child: Text(cause),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCauseArea = value;
                        });
                        _performSearch();
                      },
                    ),
                  ),
                ],
              ),

              // Status filter
              Row(
                children: [
                  const Text('Status: '),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String?>(
                      value: _selectedStatus,
                      isExpanded: true,
                      hint: const Text('All Status'),
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('All Status'),
                        ),
                        DropdownMenuItem(
                          value: 'upcoming',
                          child: Text('Upcoming'),
                        ),
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                        _performSearch();
                      },
                    ),
                  ),
                ],
              ),
              const Divider(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.volunteer_activism,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No projects found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new opportunities',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildFeaturedSection(List<ProjectModel> featuredProjects) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Featured Projects',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: featuredProjects.length,
              itemBuilder: (context, index) {
                return _buildFeaturedCard(featuredProjects[index]);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(ProjectModel project) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(projectId: project.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.7),
                      AppTheme.primaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.volunteer_activism,
                    size: 48,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      project.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            project.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd').format(project.startDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(project).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusText(project),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getStatusColor(project),
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  SliverList _buildProjectsList(ProjectProvider projectProvider) {
    final projects = projectProvider.searchResults.isNotEmpty
        ? projectProvider.searchResults
        : projectProvider.featuredProjects;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0 && projectProvider.searchResults.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '${projectProvider.totalProjects} Projects Found',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final actualIndex = projectProvider.searchResults.isNotEmpty ? index - 1 : index;
          if (actualIndex < 0 || actualIndex >= projects.length) {
            return const SizedBox.shrink();
          }

          return _buildProjectTile(projects[actualIndex]);
        },
        childCount: projects.length + (projectProvider.searchResults.isNotEmpty ? 1 : 0),
      ),
    );
  }

  Widget _buildProjectTile(ProjectModel project) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(projectId: project.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            project.organizerName ?? 'Community Organizer',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(project).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(project),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(project),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  project.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.location_on,
                      project.location,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      Icons.calendar_today,
                      DateFormat('MMM dd, yyyy').format(project.startDate),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.group,
                      '${project.currentVolunteers}/${project.maxVolunteers} volunteers',
                    ),
                    const SizedBox(width: 12),
                    if (project.pointsMultiplier != null && project.pointsMultiplier! > 1)
                      _buildInfoChip(
                        Icons.star,
                        '${project.pointsMultiplier}x points',
                        color: Colors.orange,
                      ),
                  ],
                ),
                if (project.causeAreas.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: project.causeAreas.take(3).map((cause) {
                      return Chip(
                        label: Text(
                          cause,
                          style: const TextStyle(fontSize: 10),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ProjectModel project) {
    if (project.isCompleted) return Colors.grey;
    if (project.isInProgress) return Colors.green;
    if (project.isFuture) return Colors.blue;
    return Colors.orange;
  }

  String _getStatusText(ProjectModel project) {
    if (project.isCompleted) return 'Completed';
    if (project.isInProgress) return 'In Progress';
    if (project.isFuture) return 'Upcoming';
    return 'Open';
  }
}