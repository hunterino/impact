import 'package:flutter/foundation.dart';
import 'package:serve_to_be_free/core/services/auth_service.dart';
import 'package:serve_to_be_free/features/auth/models/user_model.dart';

/// Provider for managing authentication state throughout the app.
/// Wraps AuthService and exposes authentication state to the widget tree.
class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  UserModel? get user => _authService.currentUser;
  bool get isAuthenticated => user != null;

  AuthProvider(this._authService) {
    // Listen to auth state changes from the service
    _authService.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  /// Login with email and password
  Future<UserModel> login(String email, String password) async {
    final user = await _authService.loginWithEmailAndPassword(email, password);
    notifyListeners();
    return user;
  }

  /// Register a new user
  Future<UserModel> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? location,
  }) async {
    final user = await _authService.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      location: location,
    );
    notifyListeners();
    return user;
  }

  /// Login with social media provider
  Future<UserModel> loginWithSocial(String provider) async {
    final user = await _authService.loginWithSocialMedia(provider);
    notifyListeners();
    return user;
  }

  /// Logout the current user
  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  /// Request password reset
  Future<bool> resetPassword(String email) async {
    return await _authService.resetPassword(email);
  }

  /// Update user password
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    return await _authService.updatePassword(currentPassword, newPassword);
  }
}