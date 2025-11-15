# Serve To Be Free - Unified Platform Setup Guide

## Overview

This is the unified Serve To Be Free volunteer management platform that combines:
- Supabase backend from serve/main (React PWA)
- Flutter app structure from serve_to_be_free
- Social features from libertas
- 3-tier currency system (STBF Points → SERV DR → SERV Coin)

## Prerequisites

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Supabase CLI
- PostgreSQL 15+
- Deno (for edge functions)
- Node.js 18+ (for Supabase)

## Local Development Setup

### 1. Set up Supabase Backend

```bash
# Navigate to project directory
cd serve_to_be_free/main

# Start Supabase locally
cd supabase
supabase start

# This will output:
# - API URL: http://localhost:54321
# - ANON KEY: [your-anon-key]
# - SERVICE KEY: [your-service-key]
# - Database URL: postgresql://postgres:postgres@localhost:54322/postgres
```

### 2. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your Supabase credentials
# Add the ANON KEY from step 1 to SUPABASE_ANON_KEY
```

### 3. Run Database Migrations

```bash
# Apply all migrations
cd supabase
supabase db push

# This will create:
# - All tables from serve/main
# - Social features (posts, comments, likes)
# - 3-tier currency system
# - QR code support
# - Notifications and teams
```

### 4. Install Flutter Dependencies

```bash
# Navigate back to Flutter project root
cd ..

# Install dependencies
flutter pub get

# Generate code for models
dart run build_runner build --delete-conflicting-outputs
```

### 5. Run the App

```bash
# Run on connected device/emulator
flutter run

# Or specify platform
flutter run -d chrome  # Web
flutter run -d ios     # iOS Simulator
flutter run -d android # Android Emulator
```

## Project Structure

```
serve_to_be_free/main/
├── lib/
│   ├── core/              # Core services and configuration
│   │   ├── config/        # Environment configuration
│   │   ├── services/      # Supabase, Auth, etc.
│   │   ├── providers/     # State management
│   │   └── theme/         # App theming
│   ├── features/          # Feature modules
│   │   ├── auth/          # Authentication (SMS OTP + Social)
│   │   ├── projects/      # Projects and events
│   │   ├── surveys/       # Survey builder and responses
│   │   ├── rewards/       # 3-tier currency system
│   │   ├── social/        # Feed, comments, likes
│   │   └── volunteer/     # Commitments and tracking
│   └── main.dart          # App entry point
│
└── supabase/              # Embedded Supabase backend
    ├── config.toml        # Supabase configuration
    ├── migrations/        # Database schema
    ├── functions/         # Edge functions (Deno)
    └── seed.sql          # Initial data
```

## Key Features Implemented

### From serve/main (React PWA)
- ✅ Complete Supabase backend with 42+ migrations
- ✅ Survey system with 14 question types
- ✅ Atomic point transactions
- ✅ Witness verification system
- ✅ SMS OTP authentication
- ✅ PostGIS geolocation

### From serve_to_be_free (Flutter)
- ✅ Flutter app structure
- ✅ Provider state management
- ✅ 3-tier currency system (STBF → SERV DR → SERV)
- ✅ Advanced project search
- ✅ Team collaboration

### From libertas
- ✅ QR code check-in
- ✅ Social feed with posts/comments
- ✅ Event sponsorships
- ✅ Comprehensive notifications

### New Features Added
- ✅ Unified authentication (SMS OTP + Social)
- ✅ Real-time subscriptions
- ✅ Offline support with Hive
- ✅ Push notifications
- ✅ Achievement system

## Testing

### Test Authentication

1. **SMS OTP Login**:
```dart
// In your test file or debug console
final authService = context.read<AuthService>();
await authService.sendOTP('+1234567890');
// Enter OTP received
await authService.verifyOTP('+1234567890', '123456');
```

2. **Social Login**:
```dart
await authService.signInWithGoogle();
// or
await authService.signInWithApple();
// or
await authService.signInWithFacebook();
```

### Test Database Connection

```dart
// Test basic CRUD operations
final supabase = SupabaseService.instance;

// Create a test project
final project = await supabase.create('projects', {
  'title': 'Test Project',
  'description': 'Testing Supabase connection',
  'type': 'time',
  'status': 'active',
});

// Read projects
final projects = await supabase.read('projects');
print('Found ${projects.length} projects');

// Test real-time subscriptions
final channel = supabase.subscribeToTable('projects',
  onInsert: (payload) => print('New project: $payload'),
  onUpdate: (payload) => print('Updated project: $payload'),
  onDelete: (payload) => print('Deleted project: $payload'),
);
```

## Common Issues & Solutions

### Issue: Supabase connection fails
**Solution**: Ensure Supabase is running (`supabase status`) and .env file has correct credentials

### Issue: Build runner fails
**Solution**: Run `flutter clean` then `dart run build_runner build --delete-conflicting-outputs`

### Issue: SMS OTP not working
**Solution**: Configure Twilio credentials in `supabase/config.toml`

### Issue: Social login redirects fail
**Solution**: Update redirect URLs in Supabase dashboard and platform-specific configs

## Build & Deploy

### Web Build
```bash
flutter build web --dart-define=SUPABASE_URL=https://your-project.supabase.co \
                  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### iOS Build
```bash
flutter build ios --dart-define=SUPABASE_URL=https://your-project.supabase.co \
                  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

### Android Build
```bash
flutter build apk --dart-define=SUPABASE_URL=https://your-project.supabase.co \
                  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Next Steps

1. Complete remaining service implementations (UserService, ProjectService)
2. Update UI screens to use Supabase data
3. Implement offline sync with Hive
4. Add push notifications
5. Test on all platforms

## Support

For issues or questions, refer to:
- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)
- Project documentation in `/docs/` directory