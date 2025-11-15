# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Serve To Be Free** is a volunteer service and rewards management Flutter application built on the 5x platform architecture. The app connects volunteers with service opportunities, tracks their contributions, and provides a rewards/points system. It uses MQTT for real-time messaging and communication with backend services.

## Development Commands

### Setup & Dependencies
```bash
# Install dependencies
flutter pub get

# Generate code for models (json_serializable, hive)
dart run build_runner build

# Watch mode for continuous code generation during development
dart run build_runner watch

# Clean and regenerate all generated files
dart run build_runner build --delete-conflicting-outputs
```

### Running the App
```bash
# Run on connected device/emulator
flutter run

# Run with specific device
flutter devices  # List available devices
flutter run -d <device-id>

# Run in debug mode (default)
flutter run --debug

# Run in release mode
flutter run --release
```

### Testing & Analysis
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Analyze code for issues
flutter analyze

# Check for outdated dependencies
flutter pub outdated
```

### Build Commands
```bash
# Build APK for Android
flutter build apk

# Build app bundle for Android
flutter build appbundle

# Build iOS app
flutter build ios

# Build macOS app
flutter build macos

# Build web app
flutter build web
```

## Architecture

### Feature-Based Organization

The codebase follows a feature-first architecture under `lib/features/`:

- **auth** - Authentication, registration, login (including social login)
- **home** - Main dashboard and navigation shell
- **profile** - User profile management and statistics
- **service_opportunities** - Browse and register for volunteer projects
- **volunteer_management** - Teams, commitments, service history, and hour logging
- **rewards** - Points system, rewards marketplace, ServDr currency conversion

Each feature contains:
- `screens/` - UI screens
- `models/` - Data models with JSON serialization
- `widgets/` - Reusable UI components specific to the feature

### Core Services Architecture

Located in `lib/core/services/`, the service layer provides centralized business logic:

#### MqttService (Foundation Layer)
The backbone of all backend communication. Implements:
- MQTT broker connection management with auto-reconnect
- Request-response pattern with timeout handling
- Topic subscription management
- Secure credential storage via `flutter_secure_storage`
- Message routing with unique request IDs

**Key Methods:**
- `initialize()` - Connect to MQTT broker
- `subscribe(topic)` - Subscribe to MQTT topic
- `publish(topic, message)` - Publish message to topic
- `request(requestTopic, responseTopic, message)` - Request-response pattern with timeout

**Connection Details:**
- Default host: `dev.2h2.us:1883`
- Credentials stored in secure storage: `mqtt_username`, `mqtt_password`, `mqtt_host`, `mqtt_port`
- Auto-reconnect enabled with keep-alive

#### AuthService
Manages user authentication through MQTT topics:
- Login topics: `stbf/auth/request` → `stbf/auth/response`
- Register topics: `stbf/register/request` → `stbf/register/response`
- Token storage in `flutter_secure_storage`
- Auth state changes via Stream
- Social authentication support

#### UserService
Handles user profile operations via MQTT

#### ProjectService
Manages volunteer project data

#### VolunteerService
Handles volunteer-specific operations (teams, commitments, service records)

#### RewardsService
Manages points, ServDr currency, and rewards marketplace

### State Management

Uses **Provider** pattern throughout:

1. **Service Providers** - Singleton instances injected at app root:
   ```dart
   Provider<MqttService>.value(value: mqttService)
   Provider<AuthService>.value(value: authService)
   Provider<UserService>.value(value: userService)
   ```

2. **ChangeNotifier Providers** - For reactive state:
   - `AuthProvider` - Wraps `AuthService`, exposes `isAuthenticated` and `user`
   - `UserProvider` - Depends on `AuthProvider`, manages user profile state

3. **Provider Dependencies**:
   ```dart
   ChangeNotifierProxyProvider<AuthProvider, UserProvider>
   ```
   The `UserProvider` depends on `AuthProvider` and is rebuilt when auth state changes.

### Data Layer

#### JSON Serialization
All models use `json_serializable` for serialization:
```dart
@JsonSerializable()
class UserModel {
  // Model fields

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
```

Generated files have `.g.dart` suffix. Run code generation after model changes.

#### Local Storage
Uses **Hive** for local data persistence:
- Initialized in `main.dart` with `Hive.initFlutter()`
- Secure storage for credentials via `flutter_secure_storage`

### Navigation Pattern

**Shell-based navigation** with `BottomNavigationBar`:
- Entry point: `AuthWrapper` checks auth state → `LoginScreen` or `HomeScreen`
- `HomeScreen` contains bottom nav with 5 tabs: Dashboard, Projects, Community, Rewards, Profile
- Direct navigation using `Navigator.push()` for detail screens

### 5x Platform Integration

This app is built for the 5x platform, which defines:

**MQTT Communication Pattern:**
- Request topics: `stbf/{feature}/request`
- Response topics: `stbf/{feature}/response`
- Each request includes a `requestId` UUID for matching responses
- All backend operations go through MQTT (no REST APIs)

**5x Data Store Topics:**
- `load/${path}` - Load JSON from path
- `save/${path}` - Save JSON to path
- `data/${path}` - Published when data changes

**Authentication:**
- Uses MQTT Go Auth plugin
- Access control granted by database records
- Supports passkeys (planned)

### Theme

Located in `lib/core/theme/app_theme.dart`:
- Dark theme by default (5x platform requirement)
- Modern, simple design
- Uses Material Design 3

## Common Development Patterns

### Adding a New Feature

1. Create feature directory structure:
   ```
   lib/features/new_feature/
   ├── screens/
   ├── models/
   └── widgets/
   ```

2. Create models with JSON serialization:
   ```dart
   @JsonSerializable()
   class NewModel {
     // fields
     factory NewModel.fromJson(Map<String, dynamic> json) => _$NewModelFromJson(json);
     Map<String, dynamic> toJson() => _$NewModelToJson(this);
   }
   ```

3. Run code generation: `dart run build_runner build`

4. Create service in `lib/core/services/` if needed

5. Add Provider if state management required

### Adding a New Screen

1. Create screen file in appropriate feature's `screens/` directory
2. If authenticated screen, access providers via `Provider.of<T>(context)`
3. Add navigation from existing screen or bottom nav
4. Use `Scaffold` with `AppBar` for consistency

### Working with MQTT

All backend communication goes through `MqttService`:

```dart
final mqttService = Provider.of<MqttService>(context, listen: false);

// Subscribe to topic
await mqttService.subscribe('stbf/feature/response');

// Publish message
await mqttService.publish('stbf/feature/request', {
  'action': 'some_action',
  'data': {}
});

// Request-response pattern (preferred)
final response = await mqttService.request(
  'stbf/feature/request',
  'stbf/feature/response',
  {
    'action': 'some_action',
    'data': {}
  }
);
```

### Model Patterns

All models should include:
- Immutable fields (final)
- `fromJson` factory constructor
- `toJson` method
- `copyWith` method for updates
- Computed getters as needed (e.g., `fullName`, `initials`)

## Important Notes

- This is a multi-platform Flutter app (iOS, Android, macOS, Web)
- MQTT is the **only** communication protocol - no REST APIs
- All authentication tokens stored securely via `flutter_secure_storage`
- Code generation required for models - always run `build_runner` after model changes
- The app uses `provider` for state management, not Riverpod or Bloc
- Dark theme is the default and primary theme
- Environment SDK: Dart ^3.7.2

## Dependencies

Key dependencies:
- **mqtt_client** - MQTT protocol implementation
- **provider** - State management
- **flutter_secure_storage** - Secure credential storage
- **hive_ce** / **hive_ce_flutter** - Local NoSQL database
- **json_annotation** / **json_serializable** - JSON serialization
- **google_fonts** - Typography
- **intl** - Internationalization
- **extractor** - Custom git dependency from `tps-reports/extractor`

Dev dependencies:
- **build_runner** - Code generation
- **hive_ce_generator** - Hive adapter generation
- **json_serializable** - JSON serialization generation
- **flutter_lints** - Linting rules
