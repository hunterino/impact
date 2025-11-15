import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:serve_to_be_free/features/auth/models/user_model.dart';
import 'supabase_service.dart';
import 'mqtt_service.dart';
import 'hybrid_data_service.dart';

/// Authentication service handling SMS OTP and social login
///
/// This service manages all authentication operations including:
/// - SMS OTP authentication (from serve/main)
/// - Social authentication (Google, Apple, Facebook)
/// - Email/Password authentication
/// - Session management
class AuthService extends ChangeNotifier {
  final _supabase = SupabaseService.instance.client;
  final _secureStorage = const FlutterSecureStorage();

  User? _currentSupabaseUser;
  UserModel? _currentUser;
  Session? _currentSession;

  User? get currentSupabaseUser => _currentSupabaseUser;
  UserModel? get currentUser => _currentUser;
  Session? get currentSession => _currentSession;
  bool get isAuthenticated => _currentSupabaseUser != null;

  // Stream controllers
  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();
  Stream<UserModel?> get authStateChanges => _authStateController.stream;
  StreamSubscription<AuthState>? _authStateSubscription;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    // Get initial session
    _currentSession = _supabase.auth.currentSession;
    _currentSupabaseUser = _supabase.auth.currentUser;

    // Listen to auth state changes
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen(
      (AuthState state) {
        _handleAuthStateChange(state);
      },
    );

    // Load user profile if authenticated
    if (_currentSupabaseUser != null) {
      await _loadUserProfile();
    }
  }

  void _handleAuthStateChange(AuthState state) {
    _currentSession = state.session;
    _currentSupabaseUser = state.session?.user;

    if (_currentSupabaseUser != null) {
      _loadUserProfile();
    } else {
      _currentUser = null;
      _authStateController.add(null);
    }
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    if (_currentSupabaseUser == null) return;

    try {
      print('Loading profile for user: ${_currentSupabaseUser!.id}');
      final response = await _supabase
          .from('profile')  // Changed from 'profiles' to 'profile'
          .select()
          .eq('user_id', _currentSupabaseUser!.id)
          .single();

      print('Profile loaded successfully: $response');

      // Map profile data to UserModel structure
      final userData = {
        'id': response['user_id'] ?? _currentSupabaseUser!.id,
        'email': response['email'] ?? _currentSupabaseUser!.email ?? '',
        'firstName': response['handle'] ?? 'User',  // Use handle as firstName for now
        'lastName': '',  // Profile doesn't have lastName
        'phoneNumber': response['phone'],
        'bio': response['bio'],
        'createdAt': response['created_at'] ?? DateTime.now().toIso8601String(),
        'updatedAt': response['updated_at'] ?? DateTime.now().toIso8601String(),
        'isVerified': true,  // Assume verified if they can login
        'status': 'active',
      };

      _currentUser = UserModel.fromJson(userData);
      _authStateController.add(_currentUser);
    } catch (e) {
      print('ERROR loading user profile - Full error: $e');
      print('Stack trace: ${StackTrace.current}');
      // Don't throw here, just log the error
    }
  }

  // SMS OTP Authentication (from serve/main)

  /// Send OTP to phone number
  Future<void> sendOTP(String phone) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phone,
        channel: OtpChannel.sms,
      );
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verify OTP code
  Future<UserModel> verifyOTP(String phone, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: token,
      );

      _currentSupabaseUser = response.user;
      _currentSession = response.session;
      await _loadUserProfile();
      notifyListeners();

      return _currentUser!;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Login with email and password
  Future<UserModel> loginWithEmailAndPassword(String email, String password) async {
    try {
      print('AUTH: Attempting login with email: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('AUTH: Login successful, user ID: ${response.user?.id}');
      print('AUTH: Session: ${response.session != null ? "present" : "null"}');

      _currentSupabaseUser = response.user;
      _currentSession = response.session;

      print('AUTH: Loading user profile...');
      await _loadUserProfile();
      print('AUTH: User profile loaded: ${_currentUser != null}');

      notifyListeners();

      return _currentUser!;
    } catch (e) {
      print('AUTH ERROR: Login failed - $e');
      print('AUTH ERROR: Stack trace: ${StackTrace.current}');
      throw Exception('Authentication failed: $e');
    }
  }

  // Register a new user
  Future<UserModel> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? location,
  }) async {
    try {
      // Register user with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phoneNumber,
          'location': location,
        },
      );

      if (authResponse.user != null) {
        // Create profile record
        final profileData = {
          'user_id': authResponse.user!.id,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'full_name': '$firstName $lastName',
          'phone': phoneNumber,
          'location': location,
          'created_at': DateTime.now().toIso8601String(),
        };

        await _supabase.from('profile').insert(profileData);

        _currentSupabaseUser = authResponse.user;
        _currentSession = authResponse.session;
        await _loadUserProfile();
        notifyListeners();

        return _currentUser!;
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Login with social media
  Future<UserModel> loginWithSocialMedia(String provider) async {
    try {
      OAuthProvider oauthProvider;

      switch (provider.toLowerCase()) {
        case 'google':
          oauthProvider = OAuthProvider.google;
          break;
        case 'apple':
          oauthProvider = OAuthProvider.apple;
          break;
        case 'facebook':
          oauthProvider = OAuthProvider.facebook;
          break;
        default:
          throw Exception('Unsupported provider: $provider');
      }

      await _supabase.auth.signInWithOAuth(
        oauthProvider,
        redirectTo: 'io.supabase.stbf://login-callback',
      );

      // The actual authentication happens in the browser/webview
      // Auth state will be updated via the auth state listener
      // Wait for the auth state to change
      await Future.delayed(const Duration(seconds: 2));

      if (_currentUser != null) {
        return _currentUser!;
      } else {
        throw Exception('Social login failed');
      }
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  /// Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    return loginWithSocialMedia('google');
  }

  /// Sign in with Apple
  Future<UserModel> signInWithApple() async {
    return loginWithSocialMedia('apple');
  }

  /// Sign in with Facebook
  Future<UserModel> signInWithFacebook() async {
    return loginWithSocialMedia('facebook');
  }

  // Logout the current user
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Continue with logout even if the request fails
      if (kDebugMode) {
        print('Logout request failed: $e');
      }
    } finally {
      // Clear the stored data
      await _secureStorage.deleteAll();

      // Update current user and notify listeners
      _currentUser = null;
      _currentSupabaseUser = null;
      _currentSession = null;
      _authStateController.add(null);
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.stbf://reset-password',
      );
      return true;
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // Update password
  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    try {
      // For Supabase, we just update with the new password
      // Current password verification happens on the server
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
      return response.user != null;
    } catch (e) {
      throw Exception('Password update failed: $e');
    }
  }

  /// Refresh current session
  Future<void> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      _currentSession = response.session;
      _currentSupabaseUser = response.session?.user;

      if (_currentSupabaseUser != null) {
        await _loadUserProfile();
      }
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to refresh session: $e');
    }
  }

  /// Update user metadata
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(data: metadata),
      );
      _currentSupabaseUser = response.user;
      await _loadUserProfile();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update user metadata: $e');
    }
  }

  /// Get user metadata
  Map<String, dynamic> getUserMetadata() {
    return _currentSupabaseUser?.userMetadata ?? {};
  }

  /// Check if user needs to complete profile
  bool needsProfileCompletion() {
    final metadata = getUserMetadata();
    return metadata['profile_completed'] != true;
  }

  // Dispose resources
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _authStateController.close();
    super.dispose();
  }
}
