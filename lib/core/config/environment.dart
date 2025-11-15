/// Environment configuration for the app
///
/// This file contains all environment-specific configuration values.
/// In production, these values should be provided via --dart-define
/// during the build process for security.

class Environment {
  // Private constructor to prevent instantiation
  Environment._();

  /// Supabase URL
  /// Development: http://localhost:54321
  /// Production: https://your-project.supabase.co
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321', // Local development default
  );

  /// Supabase Anonymous Key
  /// This key is safe to use in client-side code
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH', // Local dev key
  );

  /// Google Maps API Key (optional)
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// App Environment
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  /// Feature Flags
  static const bool enableBiometricAuth = bool.fromEnvironment(
    'ENABLE_BIOMETRIC_AUTH',
    defaultValue: true,
  );

  static const bool enablePushNotifications = bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
    defaultValue: true,
  );

  static const bool enableOfflineMode = bool.fromEnvironment(
    'ENABLE_OFFLINE_MODE',
    defaultValue: true,
  );

  /// Debug Settings
  static const bool enableDebugLogging = bool.fromEnvironment(
    'ENABLE_DEBUG_LOGGING',
    defaultValue: true,
  );

  /// API Configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;

  /// Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB

  /// Helper methods
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';

  /// Validate configuration
  static bool validate() {
    print('=== Environment Configuration ===');
    print('Supabase URL: $supabaseUrl');
    print('Environment: $environment');
    print('Offline Mode: ${enableOfflineMode ? "Enabled" : "Disabled"}');

    if (supabaseUrl.startsWith('http://127.0.0.1') || supabaseUrl.startsWith('http://localhost')) {
      print('Info: Using local Supabase instance');
    }
    if (supabaseAnonKey.startsWith('sb_publishable_')) {
      print('Info: Using local development Supabase key');
    }

    print('================================\n');
    return true;
  }
}