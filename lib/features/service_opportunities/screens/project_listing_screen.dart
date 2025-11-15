import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serve_to_be_free/core/providers/project_provider.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/service_opportunities/widgets/project_card.dart';
import 'package:serve_to_be_free/features/service_opportunities/widgets/search_filter_bar.dart';
import 'package:serve_to_be_free/features/service_opportunities/screens/project_detail_screen.dart';

class ProjectListingScreen extends StatefulWidget {
  const ProjectListingScreen({Key? key}) : super(key: key);

  @override
  State<ProjectListingScreen> createState() => _ProjectListingScreenState();
}

class _ProjectListingScreenState extends State<ProjectListingScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _searchQuery;
  List<String>? _selectedCauseAreas;
  DateTime? _selectedDate;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupScrollListener();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
      projectProvider.fetchCauseAreas();
      projectProvider.fetchFeaturedProjects();
      projectProvider.searchProjects();
    });
  }
  
  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreProjects();
      }
    });
  }
  
  void _loadMoreProjects() {
    Provider.of<ProjectProvider>(context, listen: false).loadMoreSearchResults(
      query: _searchQuery,
      causeAreas: _selectedCauseAreas,
      startDate: _selectedDate,
    );
  }
  
  void _handleSearch(String? query) {
    setState(() {
      _searchQuery = query;
    });
    
    Provider.of<ProjectProvider>(context, listen: false).searchProjects(
      query: query,
      causeAreas: _selectedCauseAreas,
      startDate: _selectedDate,
    );
  }
  
  void _handleFilterChange({
    List<String>? causeAreas,
    DateTime? date,
  }) {
    setState(() {
      _selectedCauseAreas = causeAreas;
      _selectedDate = date;
    });
    
    Provider.of<ProjectProvider>(context, listen: false).searchProjects(
      query: _searchQuery,
      causeAreas: causeAreas,
      startDate: date,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Opportunities'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          SearchFilterBar(
            onSearch: _handleSearch,
            onFilterChange: _handleFilterChange,
          ),
          
          // Projects List
          Expanded(
            child: Consumer<ProjectProvider>(
              builder: (context, projectProvider, child) {
                if (projectProvider.isLoading && 
                    projectProvider.searchResults.isEmpty &&
                    projectProvider.featuredProjects.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Featured Projects
                    if (projectProvider.featuredProjects.isNotEmpty && 
                        _searchQuery == null && 
                        _selectedCauseAreas == null &&
                        _selectedDate == null)
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Featured Projects',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 220,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemCount: projectProvider.featuredProjects.length,
                                itemBuilder: (context, index) {
                                  final project = projectProvider.featuredProjects[index];
                                  return SizedBox(
                                    width: 280,
                                    child: ProjectCard(
                                      project: project,
                                      isFeatured: true,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProjectDetailScreen(
                                              projectId: project.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // All Projects or Search Results
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          _searchQuery != null || _selectedCauseAreas != null || _selectedDate != null
                              ? 'Search Results (${projectProvider.totalProjects})'
                              : 'All Projects',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    if (projectProvider.searchResults.isEmpty && !projectProvider.isLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              'No projects found. Try adjusting your filters.',
                              style: TextStyle(
                                color: AppTheme.textSecondaryDarkColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final project = projectProvider.searchResults[index];
                            return ProjectCard(
                              project: project,
                              isFeatured: false,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProjectDetailScreen(
                                      projectId: project.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: projectProvider.searchResults.length,
                        ),
                      ),
                    ),
                    
                    // Loading indicator at the bottom when loading more
                    if (projectProvider.isLoading && 
                        projectProvider.searchResults.isNotEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create project screen
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Project',
      ),
    );
  }
}
