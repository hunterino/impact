import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:serve_to_be_free/core/services/mqtt_service.dart';
import 'package:serve_to_be_free/features/volunteer_management/models/commitment_model.dart';
import 'package:serve_to_be_free/features/volunteer_management/models/service_record_model.dart';
import 'package:serve_to_be_free/features/volunteer_management/models/team_model.dart';
import 'package:serve_to_be_free/features/volunteer_management/models/team_member_model.dart';

class VolunteerService {
  final MqttService _mqttService;
  
  // MQTT Topics
  static const String _volunteerRequestTopic = 'stbf/volunteer/request';
  static const String _volunteerResponseTopic = 'stbf/volunteer/response';
  static const String _teamRequestTopic = 'stbf/team/request';
  static const String _teamResponseTopic = 'stbf/team/response';
  
  VolunteerService(this._mqttService) {
    _init();
  }
  
  Future<void> _init() async {
    // Subscribe to volunteer and team response topics
    await _mqttService.subscribe(_volunteerResponseTopic);
    await _mqttService.subscribe(_teamResponseTopic);
  }
  
  // Get user commitments
  Future<List<CommitmentModel>> getUserCommitments(
    String userId,
    {String? status}
  ) async {
    try {
      final requestData = {
        'action': 'get_commitments',
        'userId': userId,
      };
      
      if (status != null) {
        requestData['status'] = status;
      }
      
      final response = await _mqttService.request(
        _volunteerRequestTopic,
        _volunteerResponseTopic,
        requestData
      );
      
      if (response['status'] == 'success') {
        final List<dynamic> commitmentsJson = response['commitments'];
        return commitmentsJson.map((json) => CommitmentModel.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get commitments');
      }
    } catch (e) {
      throw Exception('Failed to get commitments: $e');
    }
  }
  
  // Cancel commitment
  Future<bool> cancelCommitment(String userId, String commitmentId) async {
    try {
      final response = await _mqttService.request(
        _volunteerRequestTopic,
        _volunteerResponseTopic,
        {
          'action': 'cancel_commitment',
          'userId': userId,
          'commitmentId': commitmentId,
        }
      );
      
      return response['status'] == 'success';
    } catch (e) {
      throw Exception('Failed to cancel commitment: $e');
    }
  }
  
  // Log service hours
  Future<ServiceRecordModel> logServiceHours(
    String userId,
    String projectId,
    String? projectSlotId,
    DateTime serviceDate,
    DateTime startTime,
    DateTime endTime,
    double hoursServed,
    List<String>? skills,
    String? notes,
  ) async {
    try {
      final response = await _mqttService.request(
        _volunteerRequestTopic,
        _volunteerResponseTopic,
        {
          'action': 'log_service_hours',
          'userId': userId,
          'projectId': projectId,
          'projectSlotId': projectSlotId,
          'serviceDate': serviceDate.toIso8601String(),
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'hoursServed': hoursServed,
          'skills': skills,
          'notes': notes,
        }
      );
      
      if (response['status'] == 'success') {
        return ServiceRecordModel.fromJson(response['serviceRecord']);
      } else {
        throw Exception(response['message'] ?? 'Failed to log service hours');
      }
    } catch (e) {
      throw Exception('Failed to log service hours: $e');
    }
  }
  
  // Get service history
  Future<List<ServiceRecordModel>> getServiceHistory(
    String userId,
    {String? status, DateTime? startDate, DateTime? endDate}
  ) async {
    try {
      final requestData = {
        'action': 'get_service_history',
        'userId': userId,
      };
      
      if (status != null) {
        requestData['status'] = status;
      }
      
      if (startDate != null) {
        requestData['startDate'] = startDate.toIso8601String();
      }
      
      if (endDate != null) {
        requestData['endDate'] = endDate.toIso8601String();
      }
      
      final response = await _mqttService.request(
        _volunteerRequestTopic,
        _volunteerResponseTopic,
        requestData
      );
      
      if (response['status'] == 'success') {
        final List<dynamic> historyJson = response['serviceRecords'];
        return historyJson.map((json) => ServiceRecordModel.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get service history');
      }
    } catch (e) {
      throw Exception('Failed to get service history: $e');
    }
  }
  
  // Get service record by ID
  Future<ServiceRecordModel> getServiceRecordById(
    String userId,
    String recordId,
  ) async {
    try {
      final response = await _mqttService.request(
        _volunteerRequestTopic,
        _volunteerResponseTopic,
        {
          'action': 'get_service_record',
          'userId': userId,
          'recordId': recordId,
        }
      );
      
      if (response['status'] == 'success') {
        return ServiceRecordModel.fromJson(response['serviceRecord']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get service record');
      }
    } catch (e) {
      throw Exception('Failed to get service record: $e');
    }
  }
  
  // Verify service hours (for project managers)
  Future<bool> verifyServiceHours(
    String managerId,
    String recordId,
    bool approved,
    String? notes,
  ) async {
    try {
      final response = await _mqttService.request(
        _volunteerRequestTopic,
        _volunteerResponseTopic,
        {
          'action': 'verify_service_hours',
          'managerId': managerId,
          'recordId': recordId,
          'approved': approved,
          'notes': notes,
        }
      );
      
      return response['status'] == 'success';
    } catch (e) {
      throw Exception('Failed to verify service hours: $e');
    }
  }
  
  // Get user teams
  Future<List<TeamModel>> getUserTeams(String userId) async {
    try {
      final response = await _mqttService.request(
        _teamRequestTopic,
        _teamResponseTopic,
        {
          'action': 'get_user_teams',
          'userId': userId,
        }
      );
      
      if (response['status'] == 'success') {
        final List<dynamic> teamsJson = response['teams'];
        return teamsJson.map((json) => TeamModel.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get teams');
      }
    } catch (e) {
      throw Exception('Failed to get teams: $e');
    }
  }
  
  // Get team details
  Future<TeamModel> getTeamById(String teamId) async {
    try {
      final response = await _mqttService.request(
        _teamRequestTopic,
        _teamResponseTopic,
        {
          'action': 'get_team',
          'teamId': teamId,
        }
      );
      
      if (response['status'] == 'success') {
        return TeamModel.fromJson(response['team']);
      } else {
        throw Exception(response['message'] ?? 'Failed to get team');
      }
    } catch (e) {
      throw Exception('Failed to get team: $e');
    }
  }
  
  // Get team members
  Future<List<TeamMemberModel>> getTeamMembers(String teamId) async {
    try {
      final response = await _mqttService.request(
        _teamRequestTopic,
        _teamResponseTopic,
        {
          'action': 'get_team_members',
          'teamId': teamId,
        }
      );
      
      if (response['status'] == 'success') {
        final List<dynamic> membersJson = response['members'];
        return membersJson.map((json) => TeamMemberModel.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get team members');
      }
    } catch (e) {
      throw Exception('Failed to get team members: $e');
    }
  }
  
  // Create team
  Future<TeamModel> createTeam(
    String userId,
    String name,
    String? description,
    List<String>? focusAreas,
  ) async {
    try {
      final response = await _mqttService.request(
        _teamRequestTopic,
        _teamResponseTopic,
        {
          'action': 'create_team',
          'userId': userId,
          'name': name,
          'description': description,
          'focusAreas': focusAreas,
        }
      );
      
      if (response['status'] == 'success') {
        return TeamModel.fromJson(response['team']);
      } else {
        throw Exception(response['message'] ?? 'Failed to create team');
      }
    } catch (e) {
      throw Exception('Failed to create team: $e');
    }
  }
  
  // Invite to team
  Future<bool> inviteToTeam(
    String teamId,
    String inviterId,
    List<String> userIds,
  ) async {
    try {
      final response = await _mqttService.request(
        _teamRequestTopic,
        _teamResponseTopic,
        {
          'action': 'invite_to_team',
          'teamId': teamId,
          'inviterId': inviterId,
          'userIds': userIds,
        }
      );
      
      return response['status'] == 'success';
    } catch (e) {
      throw Exception('Failed to invite to team: $e');
    }
  }
  
  // Respond to team invitation
  Future<bool> respondToTeamInvitation(
    String userId,
    String teamId,
    bool accept,
  ) async {
    try {
      final response = await _mqttService.request(
        _teamRequestTopic,
        _teamResponseTopic,
        {
          'action': 'respond_to_invitation',
          'userId': userId,
          'teamId': teamId,
          'accept': accept,
        }
      );
      
      return response['status'] == 'success';
    } catch (e) {
      throw Exception('Failed to respond to invitation: $e');
    }
  }
  
  // Leave team
  Future<bool> leaveTeam(String userId, String teamId) async {
    try {
      final response = await _mqttService.request(
        _teamRequestTopic,
        _teamResponseTopic,
        {
          'action': 'leave_team',
          'userId': userId,
          'teamId': teamId,
        }
      );
      
      return response['status'] == 'success';
    } catch (e) {
      throw Exception('Failed to leave team: $e');
    }
  }
}

class VolunteerProvider with ChangeNotifier {
  final VolunteerService _volunteerService;
  
  List<CommitmentModel> _upcomingCommitments = [];
  List<CommitmentModel> _pastCommitments = [];
  List<ServiceRecordModel> _serviceHistory = [];
  List<TeamModel> _userTeams = [];
  TeamModel? _currentTeam;
  List<TeamMemberModel> _teamMembers = [];
  
  bool _isLoading = false;
  
  // Getters
  List<CommitmentModel> get upcomingCommitments => _upcomingCommitments;
  List<CommitmentModel> get pastCommitments => _pastCommitments;
  List<ServiceRecordModel> get serviceHistory => _serviceHistory;
  List<TeamModel> get userTeams => _userTeams;
  TeamModel? get currentTeam => _currentTeam;
  List<TeamMemberModel> get teamMembers => _teamMembers;
  bool get isLoading => _isLoading;
  
  VolunteerProvider(this._volunteerService);
  
  // Fetch upcoming commitments
  Future<void> fetchUpcomingCommitments(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _upcomingCommitments = await _volunteerService.getUserCommitments(
        userId,
        status: 'upcoming',
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Fetch past commitments
  Future<void> fetchPastCommitments(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _pastCommitments = await _volunteerService.getUserCommitments(
        userId,
        status: 'past',
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Cancel commitment
  Future<bool> cancelCommitment(String userId, String commitmentId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _volunteerService.cancelCommitment(userId, commitmentId);
      
      if (result) {
        // Remove the commitment from the list
        _upcomingCommitments.removeWhere((commitment) => commitment.id == commitmentId);
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
  
  // Log service hours
  Future<ServiceRecordModel> logServiceHours(
    String userId,
    String projectId,
    String? projectSlotId,
    DateTime serviceDate,
    DateTime startTime,
    DateTime endTime,
    double hoursServed,
    List<String>? skills,
    String? notes,
  ) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final serviceRecord = await _volunteerService.logServiceHours(
        userId,
        projectId,
        projectSlotId,
        serviceDate,
        startTime,
        endTime,
        hoursServed,
        skills,
        notes,
      );
      
      // Add to service history if not already present
      if (!_serviceHistory.any((record) => record.id == serviceRecord.id)) {
        _serviceHistory.add(serviceRecord);
      }
      
      _isLoading = false;
      notifyListeners();
      return serviceRecord;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Fetch service history
  Future<void> fetchServiceHistory(
    String userId, 
    {DateTime? startDate, DateTime? endDate}
  ) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _serviceHistory = await _volunteerService.getServiceHistory(
        userId,
        startDate: startDate,
        endDate: endDate,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Fetch user teams
  Future<void> fetchUserTeams(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _userTeams = await _volunteerService.getUserTeams(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Fetch team details
  Future<void> fetchTeamDetails(String teamId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentTeam = await _volunteerService.getTeamById(teamId);
      _teamMembers = await _volunteerService.getTeamMembers(teamId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Create team
  Future<TeamModel> createTeam(
    String userId,
    String name,
    String? description,
    List<String>? focusAreas,
  ) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final team = await _volunteerService.createTeam(
        userId,
        name,
        description,
        focusAreas,
      );
      
      // Add to user teams
      _userTeams.add(team);
      
      _isLoading = false;
      notifyListeners();
      return team;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Invite to team
  Future<bool> inviteToTeam(
    String teamId,
    String inviterId,
    List<String> userIds,
  ) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _volunteerService.inviteToTeam(
        teamId,
        inviterId,
        userIds,
      );
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Leave team
  Future<bool> leaveTeam(String userId, String teamId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _volunteerService.leaveTeam(userId, teamId);
      
      if (result) {
        // Remove the team from the list
        _userTeams.removeWhere((team) => team.id == teamId);
        
        // Clear current team if it's the one being left
        if (_currentTeam?.id == teamId) {
          _currentTeam = null;
          _teamMembers = [];
        }
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
}
