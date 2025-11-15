import 'dart:async';
import 'package:serve_to_be_free/core/services/mqtt_service.dart';
import 'package:serve_to_be_free/core/services/hybrid_data_service.dart';
import 'package:serve_to_be_free/core/services/offline_service.dart';
import 'package:serve_to_be_free/features/service_opportunities/models/project_model.dart';
import 'package:serve_to_be_free/features/service_opportunities/models/project_slot_model.dart';

class ProjectService {
  final MqttService _mqttService;
  final HybridDataService? _hybridDataService;
  final OfflineService? _offlineService;

  // MQTT Topics
  static const String _projectRequestTopic = 'stbf/project/request';
  static const String _projectResponseTopic = 'stbf/project/response';
  static const String _projectRealtimeTopic = 'stbf/project/realtime';

  // Stream controllers for real-time updates
  final _projectUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get projectUpdates => _projectUpdatesController.stream;

  ProjectService({
    MqttService? mqttService,
    HybridDataService? hybridDataService,
    OfflineService? offlineService,
  })  : _mqttService = mqttService ?? MqttService(),
        _hybridDataService = hybridDataService,
        _offlineService = offlineService {
    _init();
  }

  Future<void> _init() async {
    // Subscribe to project response topic
    await _mqttService.subscribe(_projectResponseTopic);

    // Subscribe to real-time updates
    await _mqttService.subscribe(_projectRealtimeTopic);

    // Listen for real-time project events
    _mqttService.messageStream
        .where((msg) => msg['topic'] == _projectRealtimeTopic)
        .listen((message) {
      _projectUpdatesController.add(message);
    });
  }
  
  // Get featured projects
  Future<List<ProjectModel>> getFeaturedProjects() async {
    // Check cache first
    if (_offlineService != null) {
      final cachedProjects = _offlineService!.getCachedData<List<dynamic>>(
        'featured_projects',
        maxAge: const Duration(minutes: 15),
      );
      if (cachedProjects != null) {
        return cachedProjects.map((json) => ProjectModel.fromJson(json)).toList();
      }
    }

    try {
      List<ProjectModel> projects;

      if (_hybridDataService != null) {
        // Use hybrid data service for fetching from Supabase
        final results = await _hybridDataService!.read<Map<String, dynamic>>(
          table: 'projects',
          filters: {'featured': true, 'status': 'active'},
          orderBy: 'created_at',
          limit: 10,
        );

        projects = results.map((json) => ProjectModel.fromJson(json)).toList();

        // Broadcast that featured projects were fetched
        await _mqttService.publish(_projectRealtimeTopic, {
          'type': 'featured_projects_fetched',
          'count': projects.length,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        // Fall back to MQTT-only approach
        final response = await _mqttService.request(
          _projectRequestTopic,
          _projectResponseTopic,
          {
            'action': 'get_featured_projects',
          }
        );

        if (response['status'] == 'success') {
          final List<dynamic> projectsJson = response['projects'];
          projects = projectsJson.map((json) => ProjectModel.fromJson(json)).toList();
        } else {
          throw Exception(response['message'] ?? 'Failed to get featured projects');
        }
      }

      // Cache the results
      await _offlineService?.cacheData(
        'featured_projects',
        projects.map((p) => p.toJson()).toList(),
      );

      return projects;
    } catch (e) {
      // Try to return cached data on error
      final cachedProjects = _offlineService?.getCachedData<List<dynamic>>('featured_projects');
      if (cachedProjects != null) {
        return cachedProjects.map((json) => ProjectModel.fromJson(json)).toList();
      }
      throw Exception('Failed to get featured projects: $e');
    }
  }
  
  // Search projects with filters
  Future<Map<String, dynamic>> searchProjects({
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
    int pageSize = 10,
  }) async {
    try {
      final requestData = {
        'action': 'search_projects',
        'page': page,
        'pageSize': pageSize,
      };
      
      if (query != null && query.isNotEmpty) {
        requestData['query'] = query;
      }
      
      if (causeAreas != null && causeAreas.isNotEmpty) {
        requestData['causeAreas'] = causeAreas;
      }
      
      if (startDate != null) {
        requestData['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        requestData['endDate'] = endDate.toIso8601String();
      }
      
      if (location != null && location.isNotEmpty) {
        requestData['location'] = location;
      }
      
      if (latitude != null && longitude != null && radius != null) {
        requestData['latitude'] = latitude;
        requestData['longitude'] = longitude;
        requestData['radius'] = radius;
      }
      
      if (requiredSkills != null && requiredSkills.isNotEmpty) {
        requestData['requiredSkills'] = requiredSkills;
      }
      
      if (status != null && status.isNotEmpty) {
        requestData['status'] = status;
      }
      
      final response = await _mqttService.request(
        _projectRequestTopic,
        _projectResponseTopic,
        requestData
      );
      
      if (response['status'] == 'success') {
        final List<dynamic> projectsJson = response['projects'];
        final projects = projectsJson.map((json) => ProjectModel.fromJson(json)).toList();
        
        return {
          'projects': projects,
          'totalProjects': response['totalProjects'],
          'totalPages': response['totalPages'],
          'currentPage': response['currentPage'],
        };
      } else {
        throw Exception(response['message'] ?? 'Failed to search projects');
      }
    } catch (e) {
      throw Exception('Failed to search projects: $e');
    }
  }
  
  // Get project details by ID
  Future<ProjectModel> getProjectById(String projectId) async {
    try {
      final response = await _mqttService.request(
        _projectRequestTopic,
        _projectResponseTopic,
        {
          'action': 'get_project',
          'projectId': projectId,
        }
      );
      
      if (response['status'] == 'success') {
        return ProjectModel.fromJson(response['project']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get project');
      }
    } catch (e) {
      throw Exception('Failed to get project: $e');
    }
  }
  
  // Get project slots
  Future<List<ProjectSlotModel>> getProjectSlots(String projectId) async {
    try {
      final response = await _mqttService.request(
        _projectRequestTopic,
        _projectResponseTopic,
        {
          'action': 'get_project_slots',
          'projectId': projectId,
        }
      );
      
      if (response['status'] == 'success') {
        final List<dynamic> slotsJson = response['slots'];
        return slotsJson.map((json) => ProjectSlotModel.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get project slots');
      }
    } catch (e) {
      throw Exception('Failed to get project slots: $e');
    }
  }
  
  // Register for a project
  Future<bool> registerForProject(
    String userId,
    String projectId,
    String? slotId,
    int numberOfVolunteers,
  ) async {
    try {
      final requestData = {
        'action': 'register_for_project',
        'userId': userId,
        'projectId': projectId,
        'numberOfVolunteers': numberOfVolunteers,
      };
      
      if (slotId != null) {
        requestData['slotId'] = slotId;
      }
      
      final response = await _mqttService.request(
        _projectRequestTopic,
        _projectResponseTopic,
        requestData
      );
      
      return response['status'] == 'success';
    } catch (e) {
      throw Exception('Failed to register for project: $e');
    }
  }
  
  // Cancel project registration
  Future<bool> cancelProjectRegistration(
    String userId,
    String projectId,
    String? slotId,
  ) async {
    try {
      final requestData = {
        'action': 'cancel_registration',
        'userId': userId,
        'projectId': projectId,
      };
      
      if (slotId != null) {
        requestData['slotId'] = slotId;
      }
      
      final response = await _mqttService.request(
        _projectRequestTopic,
        _projectResponseTopic,
        requestData
      );
      
      return response['status'] == 'success';
    } catch (e) {
      throw Exception('Failed to cancel registration: $e');
    }
  }
  
  // Create a new project
  Future<ProjectModel> createProject(Map<String, dynamic> projectData) async {
    try {
      ProjectModel newProject;

      if (_hybridDataService != null) {
        // Use hybrid data service for creating in Supabase and broadcasting
        final result = await _hybridDataService!.create<Map<String, dynamic>>(
          table: 'projects',
          data: projectData,
          broadcast: true, // Broadcast creation via MQTT
        );

        newProject = ProjectModel.fromJson(result);

        // Send detailed real-time notification via MQTT
        await _mqttService.publish(_projectRealtimeTopic, {
          'type': 'project_created',
          'project': newProject.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Clear featured projects cache since there's a new project
        await _offlineService?.clearCache(pattern: 'featured_projects');
      } else {
        // Fall back to MQTT-only approach
        final response = await _mqttService.request(
          _projectRequestTopic,
          _projectResponseTopic,
          {
            'action': 'create_project',
            'projectData': projectData,
          }
        );

        if (response['status'] == 'success') {
          newProject = ProjectModel.fromJson(response['project']);
        } else {
          throw Exception(response['message'] ?? 'Failed to create project');
        }
      }

      return newProject;
    } catch (e) {
      // If offline, queue the creation
      if (_offlineService != null && !_mqttService.isConnected) {
        await _offlineService!.queueOperation(
          'create_project',
          projectData,
          priority: 2, // High priority for project creation
        );
        // Return optimistic result
        return ProjectModel.fromJson({
          ...projectData,
          'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      throw Exception('Failed to create project: $e');
    }
  }
  
  // Update an existing project
  Future<ProjectModel> updateProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _mqttService.request(
        _projectRequestTopic,
        _projectResponseTopic,
        {
          'action': 'update_project',
          'projectId': projectId,
          'updates': updates,
        }
      );
      
      if (response['status'] == 'success') {
        return ProjectModel.fromJson(response['project']);
      } else {
        throw Exception(response['message'] ?? 'Failed to update project');
      }
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }
  
  // Get cause areas
  Future<List<String>> getCauseAreas() async {
    try {
      final response = await _mqttService.request(
        _projectRequestTopic,
        _projectResponseTopic,
        {
          'action': 'get_cause_areas',
        }
      );

      if (response['status'] == 'success') {
        final List<dynamic> causeAreas = response['causeAreas'];
        return causeAreas.map((area) => area.toString()).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get cause areas');
      }
    } catch (e) {
      throw Exception('Failed to get cause areas: $e');
    }
  }

  // Subscribe to real-time project updates
  void subscribeToProjectUpdates() {
    if (_hybridDataService != null) {
      _hybridDataService!.subscribeToTable(
        table: 'projects',
        onEvent: (event) {
          _projectUpdatesController.add({
            'type': event.type.toString(),
            'project': event.data,
            'timestamp': event.timestamp.toIso8601String(),
          });

          // Clear relevant caches when projects are updated
          if (event.type == HybridEventType.created ||
              event.type == HybridEventType.updated ||
              event.type == HybridEventType.deleted) {
            _offlineService?.clearCache(pattern: 'featured_projects');
            _offlineService?.clearCache(pattern: 'project_${event.data['id']}');
          }
        },
      );
    }
  }

  // Subscribe to a specific project's updates
  void subscribeToProject(String projectId) {
    final topic = '$_projectRealtimeTopic/$projectId';
    _mqttService.subscribe(topic);
  }

  // Unsubscribe from a specific project's updates
  void unsubscribeFromProject(String projectId) {
    // This would be implemented if MQTT client supports unsubscribe
    // For now, just stop processing messages for this project
  }

  // Dispose resources
  void dispose() {
    _projectUpdatesController.close();
  }
}
