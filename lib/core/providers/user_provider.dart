import 'package:flutter/foundation.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/services/user_service.dart';
import 'package:serve_to_be_free/features/auth/models/user_model.dart';
import 'package:serve_to_be_free/features/auth/models/skill_model.dart';

/// Provider for managing user profile data and related operations.
/// Depends on AuthProvider for authentication state.
class UserProvider with ChangeNotifier {
  final UserService _userService;
  final AuthProvider _authProvider;

  UserModel? _user;
  bool _isLoading = false;
  List<SkillModel> _skills = [];

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  List<SkillModel> get skills => _skills;

  UserProvider(this._userService, this._authProvider, [this._user]);

  /// Fetch and update current user profile
  Future<void> fetchUserProfile() async {
    if (_authProvider.user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _user = await _userService.getUserProfile(_authProvider.user!.id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update user profile with new data
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_authProvider.user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _user = await _userService.updateUserProfile(_authProvider.user!.id, updates);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch user skills
  Future<void> fetchSkills() async {
    if (_authProvider.user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _skills = await _userService.getUserSkills(_authProvider.user!.id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update user skills
  Future<void> updateSkills(List<SkillModel> skills) async {
    if (_authProvider.user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _skills = await _userService.updateUserSkills(_authProvider.user!.id, skills);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get user service history with pagination
  Future<Map<String, dynamic>> getServiceHistory({int page = 1, int pageSize = 10}) async {
    if (_authProvider.user == null) {
      throw Exception('User not authenticated');
    }

    return await _userService.getUserServiceHistory(
      _authProvider.user!.id,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Get user notifications with pagination
  Future<List<dynamic>> getNotifications({int page = 1, int pageSize = 20}) async {
    if (_authProvider.user == null) {
      throw Exception('User not authenticated');
    }

    return await _userService.getUserNotifications(
      _authProvider.user!.id,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Mark a notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    if (_authProvider.user == null) {
      throw Exception('User not authenticated');
    }

    return await _userService.markNotificationAsRead(
      _authProvider.user!.id,
      notificationId,
    );
  }
}