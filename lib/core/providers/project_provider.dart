import 'package:flutter/foundation.dart';
import 'package:serve_to_be_free/core/services/project_service.dart';
import 'package:serve_to_be_free/features/service_opportunities/models/project_model.dart';
import 'package:serve_to_be_free/features/service_opportunities/models/project_slot_model.dart';

/// Provider for managing project/service opportunity data.
class ProjectProvider with ChangeNotifier {
  final ProjectService _projectService;

  List<ProjectModel> _featuredProjects = [];
  List<ProjectModel> _searchResults = [];
  ProjectModel? _currentProject;
  List<ProjectSlotModel> _currentProjectSlots = [];
  List<String> _causeAreas = [];
  bool _isLoading = false;
  int _totalProjects = 0;
  int _currentPage = 1;
  int _totalPages = 1;

  // Getters
  List<ProjectModel> get featuredProjects => _featuredProjects;
  List<ProjectModel> get searchResults => _searchResults;
  ProjectModel? get currentProject => _currentProject;
  List<ProjectSlotModel> get currentProjectSlots => _currentProjectSlots;
  List<String> get causeAreas => _causeAreas;
  bool get isLoading => _isLoading;
  int get totalProjects => _totalProjects;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  ProjectProvider(this._projectService);

  /// Fetch featured projects for home/dashboard display
  Future<void> fetchFeaturedProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _featuredProjects = await _projectService.getFeaturedProjects();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Search projects with various filters
  Future<void> searchProjects({
    String? query,
    List<String>? causeAreas,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    double? latitude,
    double? longitude,
    double? radius,
    List<String>? requiredSkills,
    String? status,
    int page = 1,
    bool reset = true,
  }) async {
    _isLoading = true;
    if (reset) {
      _searchResults = [];
    }
    notifyListeners();

    try {
      final result = await _projectService.searchProjects(
        query: query,
        causeAreas: causeAreas,
        startDate: startDate,
        endDate: endDate,
        location: location,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        requiredSkills: requiredSkills,
        status: status,
        page: page,
      );

      final List<ProjectModel> projects = result['projects'];
      _totalProjects = result['totalProjects'];
      _totalPages = result['totalPages'];
      _currentPage = result['currentPage'];

      if (reset) {
        _searchResults = projects;
      } else {
        _searchResults.addAll(projects);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Load more search results (pagination)
  Future<void> loadMoreSearchResults({
    String? query,
    List<String>? causeAreas,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    double? latitude,
    double? longitude,
    double? radius,
    List<String>? requiredSkills,
    String? status,
  }) async {
    if (_currentPage < _totalPages && !_isLoading) {
      await searchProjects(
        query: query,
        causeAreas: causeAreas,
        startDate: startDate,
        endDate: endDate,
        location: location,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        requiredSkills: requiredSkills,
        status: status,
        page: _currentPage + 1,
        reset: false,
      );
    }
  }

  /// Get project details by ID
  Future<void> fetchProjectDetails(String projectId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentProject = await _projectService.getProjectById(projectId);
      _currentProjectSlots = await _projectService.getProjectSlots(projectId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Register for a project
  Future<bool> registerForProject(
    String userId,
    String projectId,
    String? slotId,
    int numberOfVolunteers,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _projectService.registerForProject(
        userId,
        projectId,
        slotId,
        numberOfVolunteers,
      );

      if (result && _currentProject?.id == projectId) {
        // Refresh project details to get updated counts
        await fetchProjectDetails(projectId);
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Cancel project registration
  Future<bool> cancelProjectRegistration(
    String userId,
    String projectId,
    String? slotId,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _projectService.cancelProjectRegistration(
        userId,
        projectId,
        slotId,
      );

      if (result && _currentProject?.id == projectId) {
        // Refresh project details to get updated counts
        await fetchProjectDetails(projectId);
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Create a new project
  Future<ProjectModel> createProject(Map<String, dynamic> projectData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final project = await _projectService.createProject(projectData);
      _isLoading = false;
      notifyListeners();
      return project;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing project
  Future<ProjectModel> updateProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final project = await _projectService.updateProject(projectId, updates);

      if (_currentProject?.id == projectId) {
        _currentProject = project;
      }

      _isLoading = false;
      notifyListeners();
      return project;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch available cause areas
  Future<void> fetchCauseAreas() async {
    if (_causeAreas.isNotEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      _causeAreas = await _projectService.getCauseAreas();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}