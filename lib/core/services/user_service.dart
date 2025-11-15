import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:serve_to_be_free/core/services/mqtt_service.dart';
import 'package:serve_to_be_free/core/services/hybrid_data_service.dart';
import 'package:serve_to_be_free/core/services/offline_service.dart';
import 'package:serve_to_be_free/features/auth/models/user_model.dart';
import 'package:serve_to_be_free/features/auth/models/skill_model.dart';

/// Helper function to deeply convert Map<dynamic, dynamic> to Map<String, dynamic>
Map<String, dynamic> _deepConvertMap(dynamic data) {
  if (data == null) {
    return {};
  }

  if (data is! Map) {
    throw ArgumentError('Data must be a Map, got ${data.runtimeType}');
  }

  return Map<String, dynamic>.fromEntries(
    data.entries.map((entry) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value is Map) {
        return MapEntry(key, _deepConvertMap(value));
      } else if (value is List) {
        return MapEntry(key, value.map((item) {
          if (item is Map) {
            return _deepConvertMap(item);
          }
          return item;
        }).toList());
      } else {
        return MapEntry(key, value);
      }
    }),
  );
}

class UserService {
  final MqttService _mqttService;
  final HybridDataService? _hybridDataService;
  final OfflineService? _offlineService;

  // MQTT Topics
  static const String _userRequestTopic = 'stbf/user/request';
  static const String _userResponseTopic = 'stbf/user/response';
  static const String _userRealtimeTopic = 'stbf/user/realtime';

  // Stream controllers for real-time updates
  final _userUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get userUpdates => _userUpdatesController.stream;

  UserService({
    MqttService? mqttService,
    HybridDataService? hybridDataService,
    OfflineService? offlineService,
  })  : _mqttService = mqttService ?? MqttService(),
        _hybridDataService = hybridDataService,
        _offlineService = offlineService {
    _init();
  }

  Future<void> _init() async {
    // Subscribe to user response topic
    await _mqttService.subscribe(_userResponseTopic);

    // Subscribe to real-time updates
    await _mqttService.subscribe(_userRealtimeTopic);

    // Listen for real-time user events
    _mqttService.messageStream
        .where((msg) => msg['topic'] == _userRealtimeTopic)
        .listen((message) {
      _userUpdatesController.add(message);
    });
  }

  // Get user profile details
  Future<UserModel> getUserProfile(String userId) async {
    // Check cache first if available
    if (_offlineService != null) {
      final cachedProfile = _offlineService!.getCachedData<Map<String, dynamic>>(
        'user_profile_$userId',
        maxAge: const Duration(minutes: 30),
      );
      if (cachedProfile != null) {
        // Deep convert to fix type issues
        final profileMap = _deepConvertMap(cachedProfile);
        return UserModel.fromJson(profileMap);
      }
    }

    try {
      // Use hybrid data service if available, fall back to MQTT
      if (_hybridDataService != null) {
        final profiles = await _hybridDataService!.read<Map<String, dynamic>>(
          table: 'profile',
          filters: {'user_id': userId},
          limit: 1,
        );

        if (profiles.isNotEmpty) {
          // Map profile data to UserModel with proper null handling
          // Deep convert to fix type issues
          if (kDebugMode) {
            print('DEBUG: profiles.first type: ${profiles.first.runtimeType}');
            print('DEBUG: profiles.first: ${profiles.first}');
          }
          final profileData = _deepConvertMap(profiles.first);
          final userData = {
            'id': profileData['user_id'] ?? userId,
            'email': profileData['email'] ?? '',
            'firstName': profileData['handle'] ?? 'User',
            'lastName': '',  // Profile doesn't have lastName
            'phoneNumber': profileData['phone'],
            'bio': profileData['bio'],
            'createdAt': profileData['created_at'] ?? DateTime.now().toIso8601String(),
            'updatedAt': profileData['updated_at'] ?? DateTime.now().toIso8601String(),
            'isVerified': true,
            'status': 'active',
          };

          final profile = UserModel.fromJson(userData);

          // Cache the result
          await _offlineService?.cacheData(
            'user_profile_$userId',
            profile.toJson(),
          );

          return profile;
        } else {
          throw Exception('User profile not found');
        }
      } else {
        // Fall back to MQTT-only approach
        final response = await _mqttService.request(
          _userRequestTopic,
          _userResponseTopic,
          {
            'action': 'get_profile',
            'userId': userId,
          }
        );

        if (response['status'] == 'success') {
          // Deep convert to fix type issues
          final userData = _deepConvertMap(response['user']);
          final profile = UserModel.fromJson(userData);

          // Cache the result
          await _offlineService?.cacheData(
            'user_profile_$userId',
            profile.toJson(),
          );

          return profile;
        } else {
          throw Exception(response['message'] ?? 'Failed to get user profile');
        }
      }
    } catch (e, stackTrace) {
      // Log the error for debugging
      if (kDebugMode) {
        print('DEBUG: Error in getUserProfile: $e');
        print('DEBUG: Stack trace: $stackTrace');
      }

      // Try to return cached data on error
      final cachedProfile = _offlineService?.getCachedData<Map<String, dynamic>>(
        'user_profile_$userId',
      );
      if (cachedProfile != null) {
        if (kDebugMode) {
          print('DEBUG: cachedProfile type: ${cachedProfile.runtimeType}');
        }
        // Deep convert to fix type issues
        final profileMap = _deepConvertMap(cachedProfile);
        return UserModel.fromJson(profileMap);
      }
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      UserModel updatedProfile;

      if (_hybridDataService != null) {
        // Use hybrid data service for persistence and real-time broadcast
        final result = await _hybridDataService!.update<Map<String, dynamic>>(
          table: 'profiles',
          id: userId,
          data: updates,
          broadcast: true, // Broadcast update via MQTT
        );

        updatedProfile = UserModel.fromJson(result);

        // Send real-time notification via MQTT
        await _mqttService.publish(_userRealtimeTopic, {
          'type': 'profile_updated',
          'userId': userId,
          'updates': updates,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        // Fall back to MQTT-only approach
        final requestData = {
          'action': 'update_profile',
          'userId': userId,
          ...updates,
        };

        final response = await _mqttService.request(
          _userRequestTopic,
          _userResponseTopic,
          requestData
        );

        if (response['status'] == 'success') {
          updatedProfile = UserModel.fromJson(response['user']);
        } else {
          throw Exception(response['message'] ?? 'Failed to update user profile');
        }
      }

      // Clear cache for this user
      await _offlineService?.clearCache(pattern: 'user_profile_$userId');

      // Cache the updated profile
      await _offlineService?.cacheData(
        'user_profile_$userId',
        updatedProfile.toJson(),
      );

      return updatedProfile;
    } catch (e) {
      // If offline, queue the update
      if (_offlineService != null && !await _isOnline()) {
        await _offlineService!.queueOperation(
          'update_user_profile',
          {
            'userId': userId,
            'updates': updates,
          },
          priority: 1,
        );
        // Return optimistic update
        final currentProfile = await getUserProfile(userId);
        return UserModel.fromJson({...currentProfile.toJson(), ...updates});
      }
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Helper method to check connectivity
  Future<bool> _isOnline() async {
    return _mqttService.isConnected && (_hybridDataService != null || true);
  }

  // Get user skills
  Future<List<SkillModel>> getUserSkills(String userId) async {
    try {
      final response = await _mqttService.request(
        _userRequestTopic,
        _userResponseTopic,
        {
          'action': 'get_skills',
          'userId': userId,
        }
      );

      if (response['status'] == 'success') {
        final List<dynamic> skillsJson = response['skills'];
        return skillsJson.map((json) => SkillModel.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to get user skills');
      }
    } catch (e) {
      throw Exception('Failed to get user skills: $e');
    }
  }

  // Update user skills
  Future<List<SkillModel>> updateUserSkills(
    String userId,
    List<SkillModel> skills,
  ) async {
    try {
      final skillsJson = skills.map((skill) => skill.toJson()).toList();

      final response = await _mqttService.request(
        _userRequestTopic,
        _userResponseTopic,
        {
          'action': 'update_skills',
          'userId': userId,
          'skills': skillsJson,
        }
      );

      if (response['status'] == 'success') {
        final List<dynamic> updatedSkillsJson = response['skills'];
        return updatedSkillsJson.map((json) => SkillModel.fromJson(json)).toList();
      } else {
        throw Exception(response['message'] ?? 'Failed to update user skills');
      }
    } catch (e) {
      throw Exception('Failed to update user skills: $e');
    }
  }

  // Get user service history
  Future<Map<String, dynamic>> getUserServiceHistory(
    String userId,
    {int page = 1, int pageSize = 10}
  ) async {
    try {
      final response = await _mqttService.request(
        _userRequestTopic,
        _userResponseTopic,
        {
          'action': 'get_service_history',
          'userId': userId,
          'page': page,
          'pageSize': pageSize,
        }
      );

      if (response['status'] == 'success') {
        return {
          'history': response['history'],
          'totalPages': response['totalPages'],
          'currentPage': response['currentPage'],
          'totalItems': response['totalItems'],
        };
      } else {
        throw Exception(response['message'] ?? 'Failed to get service history');
      }
    } catch (e) {
      throw Exception('Failed to get service history: $e');
    }
  }

  // Get user notifications
  Future<List<dynamic>> getUserNotifications(
    String userId,
    {int page = 1, int pageSize = 20}
  ) async {
    try {
      final response = await _mqttService.request(
        _userRequestTopic,
        _userResponseTopic,
        {
          'action': 'get_notifications',
          'userId': userId,
          'page': page,
          'pageSize': pageSize,
        }
      );

      if (response['status'] == 'success') {
        return response['notifications'];
      } else {
        throw Exception(response['message'] ?? 'Failed to get notifications');
      }
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String userId, String notificationId) async {
    try {
      final response = await _mqttService.request(
        _userRequestTopic,
        _userResponseTopic,
        {
          'action': 'mark_notification_read',
          'userId': userId,
          'notificationId': notificationId,
        }
      );

      return response['status'] == 'success';
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Get user privacy settings
  Future<Map<String, dynamic>> getUserPrivacySettings(String userId) async {
    try {
      final response = await _mqttService.request(
        _userRequestTopic,
        _userResponseTopic,
        {
          'action': 'get_privacy_settings',
          'userId': userId,
        }
      );

      if (response['status'] == 'success') {
        return response['settings'];
      } else {
        throw Exception(response['message'] ?? 'Failed to get privacy settings');
      }
    } catch (e) {
      throw Exception('Failed to get privacy settings: $e');
    }
  }

  // Update user privacy settings
  Future<bool> updateUserPrivacySettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      final response = await _mqttService.request(
        _userRequestTopic,
        _userResponseTopic,
        {
          'action': 'update_privacy_settings',
          'userId': userId,
          'settings': settings,
        }
      );

      return response['status'] == 'success';
    } catch (e) {
      throw Exception('Failed to update privacy settings: $e');
    }
  }

  // Subscribe to real-time user updates
  void subscribeToUserUpdates(String userId) {
    if (_hybridDataService != null) {
      _hybridDataService!.subscribeToTable(
        table: 'profiles',
        onEvent: (event) {
          if (event.data['user_id'] == userId) {
            _userUpdatesController.add({
              'type': event.type.toString(),
              'data': event.data,
              'timestamp': event.timestamp.toIso8601String(),
            });
          }
        },
      );
    }
  }

  // Dispose resources
  void dispose() {
    _userUpdatesController.close();
  }
}
