# Serve To Be Free - Flutter App Comprehensive Analysis

## Executive Summary

**serve_to_be_free** is a native Flutter mobile application for the "Serve To Be Free" (STBF) volunteer management platform. It's built on the 5x platform architecture using MQTT as the sole communication protocol. The app enables volunteers to discover service opportunities, track contributions, earn rewards, and engage with community features.

**Current Status:** Active development with feature-complete MVP
**Platform Support:** iOS, Android, macOS, Web (via Flutter)
**Target User:** Volunteers seeking meaningful service opportunities and community engagement

---

## 1. ARCHITECTURE & STATE MANAGEMENT

### 1.1 Overall Architecture Pattern

The app follows a **Feature-First Architecture** with clear separation of concerns:

```
lib/
├── core/                          # Shared services, providers, theme
│   ├── services/                  # Business logic layer
│   ├── providers/                 # State management (Provider pattern)
│   └── theme/                     # App theming
└── features/                      # Feature modules
    ├── auth/                      # Authentication
    ├── home/                      # Dashboard & navigation shell
    ├── service_opportunities/     # Browse & register for projects
    ├── volunteer_management/      # Teams, commitments, hours
    ├── rewards/                   # Points, wallet, redemptions
    ├── profile/                   # User profile management
    └── community/                 # Feed, teams, leaderboard
```

### 1.2 State Management: Provider Pattern

**State Management Library:** `provider` v6.1.4

The app uses a hierarchical Provider pattern combining:

#### Service Providers (Singleton Pattern)
Initialized in `main.dart` and injected at root level:
```dart
Provider<MqttService>.value(value: mqttService)
Provider<AuthService>.value(value: authService)
Provider<UserService>.value(value: userService)
Provider<ProjectService>.value(value: projectService)
```

#### ChangeNotifier Providers (Reactive State)
For reactive state management throughout the app:

1. **AuthProvider** - Wraps AuthService
   - `isAuthenticated` - Authentication status
   - `user` - Current UserModel
   - Methods: `login()`, `register()`, `loginWithSocial()`, `logout()`, `resetPassword()`

2. **UserProvider** - Depends on AuthProvider
   - `user` - User profile data
   - `isLoading` - Loading state
   - `skills` - List of user skills
   - Methods: `fetchUserProfile()`, `updateProfile()`, `fetchSkills()`, `updateSkills()`

3. **ProjectProvider** - Project/opportunity data
   - `featuredProjects` - Featured service opportunities
   - `searchResults` - Search results with pagination
   - `currentProject` - Selected project details
   - `causeAreas` - Available cause area filters
   - Methods: `fetchFeaturedProjects()`, `searchProjects()`, `fetchProjectDetails()`, `registerForProject()`

4. **RewardsProvider** - Rewards & wallet management (ChangeNotifier mixin)
   - `wallet` - WalletModel with points/SERV DR/SERV Coin balances
   - `pointsTransactions` - Transaction history
   - `availableRewards` - Reward marketplace items
   - Methods: `fetchUserWallet()`, `convertPointsToServDR()`, `redeemReward()`

5. **VolunteerProvider** - Volunteer commitments & teams (ChangeNotifier mixin)
   - `upcomingCommitments` - Future project registrations
   - `pastCommitments` - Completed projects
   - `serviceHistory` - Service record history
   - `userTeams` - User's teams
   - Methods: `fetchUpcomingCommitments()`, `logServiceHours()`, `createTeam()`, `leaveTeam()`

#### Provider Dependencies
```dart
ChangeNotifierProxyProvider<AuthProvider, UserProvider>
```
UserProvider depends on AuthProvider and rebuilds when auth state changes.

### 1.3 MQTT Service Implementation

**Foundation Layer:** `MqttService` (located in `lib/core/services/mqtt_service.dart`)

The MQTT Service is the backbone of ALL backend communication - no REST APIs are used.

#### Connection Configuration
- **Default Host:** `dev.2h2.us:1883`
- **Credentials:** Stored in `flutter_secure_storage`
  - `mqtt_username` (default: `datastore`)
  - `mqtt_password` (default: `all4Datastore!`)
  - `mqtt_host` (configurable)
  - `mqtt_port` (default: 1883)

#### Features
- **Auto-reconnect** enabled with 60-second keep-alive
- **Secure credential storage** via `flutter_secure_storage`
- **Request-response pattern** with UUID-based request tracking
- **30-second timeout** for all requests (configurable)
- **Message broadcasting** via StreamController
- **Topic subscription management**

#### Key Methods
```dart
// Initialize connection
Future<void> initialize()

// Subscribe to topic
Future<bool> subscribe(String topic, {int qos = 1})

// Publish message
Future<bool> publish(String topic, Map<String, dynamic> message, {int qos = 1})

// Request-response pattern (preferred for most operations)
Future<Map<String, dynamic>> request(
  String requestTopic,
  String responseTopic,
  Map<String, dynamic> message,
  {Duration timeout = const Duration(seconds: 30)}
)

// Disconnect
Future<void> disconnect()

// Automatic reconnection
Future<bool> reconnect()
```

#### MQTT Communication Pattern
All requests follow a topic structure:
- **Request Topics:** `stbf/{feature}/request`
- **Response Topics:** `stbf/{feature}/response`
- **Request ID:** UUID auto-generated for response matching
- **Payload:** JSON-encoded Map<String, dynamic>

Example:
```dart
final response = await mqttService.request(
  'stbf/auth/request',
  'stbf/auth/response',
  {
    'action': 'login',
    'email': email,
    'password': password,
  }
);
```

---

## 2. FEATURES OVERVIEW

### 2.1 Authentication Feature (`lib/features/auth/`)

**Purpose:** User registration, login, and session management

**Screens:**
- `LoginScreen` - Email/password login + social login (Facebook, Google, Apple)
- `RegisterScreen` - New user registration
- `ResetPasswordScreen` - Password recovery

**MQTT Topics:**
- `stbf/auth/request` / `stbf/auth/response` - Auth operations
- `stbf/register/request` / `stbf/register/response` - Registration

**AuthService Methods:**
- `loginWithEmailAndPassword(email, password)` - Standard login
- `register(email, password, firstName, lastName, phoneNumber, location)` - Register new user
- `loginWithSocialMedia(provider)` - Social authentication (facebook, google, apple)
- `validateToken(token)` - Verify stored token on app startup
- `logout()` - Session termination
- `resetPassword(email)` - Initiate password reset
- `updatePassword(currentPassword, newPassword)` - Change password

**Token Storage:**
- Tokens stored in `flutter_secure_storage` with key: `auth_token`
- Auto-login on app launch if valid token exists
- Token validation on AuthService initialization

**Models:**
- `UserModel` - User profile with JSON serialization
- `SkillModel` - User skills/interests

### 2.2 Home Feature (`lib/features/home/`)

**Purpose:** Main app shell and dashboard

**Screens:**
- `HomeScreen` - Bottom navigation shell with 5 tabs
- `DashboardScreen` - Welcome, stats overview, quick actions, recent activity

**Navigation Structure:**
Bottom Navigation with 5 tabs:
1. **Dashboard** - Overview, stats, quick actions
2. **Projects** - Browse service opportunities
3. **Community** - Social feed, teams, leaderboard
4. **Rewards** - Points, wallet, redemptions
5. **Profile** - User profile & settings

**DashboardScreen Features:**
- Welcome greeting with user's first name
- **Your Impact stats** - Service hours, projects completed, points earned, teams
- **Quick Actions** - 6 action buttons (Find Projects, Log Hours, My Teams, Schedule, Leaderboard, Rewards)
- **Recent Activity** - Latest 3 activities (completed projects, achievements, team joins)
- **Upcoming Events** - Next 2 registered projects with join CTA

### 2.3 Service Opportunities Feature (`lib/features/service_opportunities/`)

**Purpose:** Browse, search, filter, and register for volunteer projects

**Screens:**
- `ProjectsScreen` - Main projects/opportunities listing
- `ProjectListingScreen` - Filterable project browse with search
- `ProjectDetailScreen` - Full project information and registration
- `ProjectRegistrationScreen` - Register for specific project/slot
- `CreateProjectScreen` - Create new volunteer project (organizer feature)

**MQTT Topics:**
- `stbf/project/request` / `stbf/project/response`

**ProjectService Methods:**
- `getFeaturedProjects()` - Curated projects for home display
- `searchProjects(query, causeAreas, startDate, endDate, location, latitude, longitude, radius, requiredSkills, status, page, pageSize)` - Advanced search with filters
- `getProjectById(projectId)` - Detailed project information
- `getProjectSlots(projectId)` - Available time slots for project
- `registerForProject(userId, projectId, slotId, numberOfVolunteers)` - Join project
- `cancelProjectRegistration(userId, projectId, slotId)` - Withdraw from project
- `createProject(projectData)` - Create new project (organizer)
- `updateProject(projectId, updates)` - Modify project
- `getCauseAreas()` - List all cause area categories

**Search Filters:**
- Text query (title, description)
- Cause areas (e.g., environmental, education, food security)
- Date range (startDate, endDate)
- Location (text or geo-based with radius)
- Required skills
- Status (upcoming, active, completed)
- Pagination (page, pageSize)

**Models:**
- `ProjectModel` - Service opportunity with computed properties (isAtCapacity, isFuture, isInProgress, isCompleted)
- `ProjectSlotModel` - Time slot within a project

### 2.4 Volunteer Management Feature (`lib/features/volunteer_management/`)

**Purpose:** Track commitments, log service hours, manage teams

**Screens:**
- Commitment screens (view upcoming/past commitments)
- Service record screens (log and view service hours)
- Team screens (create, join, manage teams)

**MQTT Topics:**
- `stbf/volunteer/request` / `stbf/volunteer/response`
- `stbf/team/request` / `stbf/team/response`

**VolunteerService Methods:**

*Commitments:*
- `getUserCommitments(userId, status)` - Get upcoming/past registrations
- `cancelCommitment(userId, commitmentId)` - Withdraw from registered project

*Service Hours:*
- `logServiceHours(userId, projectId, serviceDate, startTime, endTime, hoursServed, skills, notes)` - Record service
- `getServiceHistory(userId, status, startDate, endDate)` - View service records
- `getServiceRecordById(userId, recordId)` - Single record details
- `verifyServiceHours(managerId, recordId, approved, notes)` - Project manager approval

*Teams:*
- `getUserTeams(userId)` - List user's teams
- `getTeamById(teamId)` - Team details
- `getTeamMembers(teamId)` - Team member list
- `createTeam(userId, name, description, focusAreas)` - Start new team
- `inviteToTeam(teamId, inviterId, userIds)` - Send team invites
- `respondToTeamInvitation(userId, teamId, accept)` - Accept/decline invite
- `leaveTeam(userId, teamId)` - Withdraw from team

**Models:**
- `CommitmentModel` - Project registration with status and time tracking
- `ServiceRecordModel` - Logged service hours with points earned and verification status
- `TeamModel` - Team information
- `TeamMemberModel` - Team member details

### 2.5 Rewards Feature (`lib/features/rewards/`)

**Purpose:** Points system, wallet management, reward marketplace

**Screens:**
- `RewardsScreen` - Main rewards hub
- `RewardsDashboardScreen` - Wallet overview
- `RewardsMarketplaceScreen` - Browse available rewards
- `RewardDetailScreen` - Single reward information
- `PointsHistoryScreen` - Transaction history
- `ConvertPointsScreen` - Convert STBF Points → SERV DR
- `ConvertServDRScreen` - Convert SERV DR → SERV Coin
- `ServDRHistoryScreen` - SERV DR transaction history
- `MyRewardsScreen` - Redeemed rewards and their status

**MQTT Topics:**
- `stbf/wallet/request` / `stbf/wallet/response`
- `stbf/rewards/request` / `stbf/rewards/response`

**RewardsService Methods:**

*Wallet Operations:*
- `getUserWallet(userId)` - Get wallet with all balances
- `getPointsTransactions(userId, page, pageSize)` - Points transaction history
- `getServDRTransactions(userId, page, pageSize)` - SERV DR transaction history

*Conversions:*
- `convertPointsToServDR(userId, pointsAmount)` - STBF Points → SERV DR
- `convertServDRToServCoin(userId, servDRAmount)` - SERV DR → SERV Coin
- `activateServCoinWallet(userId)` - Enable SERV Coin wallet

*Rewards Marketplace:*
- `getAvailableRewards(category, maxServDRCost, page, pageSize)` - Browse rewards
- `getRewardById(rewardId)` - Reward details
- `redeemReward(userId, rewardId)` - Claim reward
- `getUserRedemptions(userId, status, page, pageSize)` - User's redemptions
- `getRedemptionById(userId, redemptionId)` - Redemption details

**Reward System Architecture:**

Three-tier currency system:
1. **STBF Points** - Base currency earned through service
   - Earned on service hour logging
   - Subject to expiration
   - Tracked with next expiration date
   - Can expire soon (warning system)

2. **SERV DR** - Intermediate currency
   - Converted from STBF Points
   - Blockchain-backed digital right
   - Required for reward marketplace
   - Wallet address for tracking

3. **SERV Coin** - Final currency
   - Converted from SERV DR
   - Cryptocurrency-like mechanism
   - Requires wallet activation
   - May be used beyond platform

**Models:**
- `WalletModel` - Complete wallet with all 3 currency balances
- `PointsTransactionModel` - Individual points transaction
- `ServDRTransactionModel` - SERV DR conversion/transaction
- `RewardModel` - Reward in marketplace
- `RedemptionModel` - User's claimed reward with fulfillment status

### 2.6 Profile Feature (`lib/features/profile/`)

**Purpose:** User profile management and statistics

**Screens:**
- `ProfileScreen` - Read-only profile display with stats
- `EditProfileScreen` - Modify user information

**ProfileScreen Features:**
- Profile header with avatar (image or initials)
- User name, email, location
- Edit profile button (navigation to EditProfileScreen)
- **Stats cards** - Projects (12), Service Hours (45.5), Points (4,550)
- **Skills & Interests** - Chip-based skill display
- **Recent Service** - Last few service records

**MQTT Topics:**
- `stbf/user/request` / `stbf/user/response`

**UserService Methods:**
- `getUserProfile(userId)` - Full profile data
- `updateUserProfile(userId, updates)` - Modify profile fields
- `getUserSkills(userId)` - Skills/interests list
- `updateUserSkills(userId, skills)` - Update skills
- `getUserServiceHistory(userId, page, pageSize)` - Paginated service history
- `getUserNotifications(userId, page, pageSize)` - Notifications
- `markNotificationAsRead(userId, notificationId)` - Mark as read
- `getUserPrivacySettings(userId)` - Privacy preferences
- `updateUserPrivacySettings(userId, settings)` - Update privacy settings

**Models:**
- `UserModel` - User profile with computed properties (fullName, initials)

### 2.7 Community Feature (`lib/features/community/`)

**Purpose:** Social engagement, team collaboration, gamification

**Screens:**
- `CommunityScreen` - Tabbed interface with 3 sections

**Tabs:**

1. **Feed Tab**
   - Social activity stream
   - User posts about service experiences
   - Achievement/milestone announcements
   - Project attachments (clickable to join)
   - Floating action button to create posts
   - Interaction buttons: Like, Comment, Share

2. **Teams Tab**
   - Browse community teams
   - Team cards with member count and points
   - Join/Joined status
   - Team leader badges
   - Tap to view team details

3. **Leaderboard Tab**
   - Weekly/Monthly/All-time rankings
   - Top 3 podium view (with visual heights)
   - Ranked list (4+)
   - Points-based ranking
   - Volunteer achievements recognition

**MQTT Topics:**
- Likely `stbf/community/request` / `stbf/community/response` (implementation stub present)

**Features Demonstrated:**
- Real-time activity feed
- Gamification (leaderboards, achievements)
- Team-based collaboration
- Social sharing capabilities
- Milestone celebrations

---

## 3. AUTHENTICATION & SECURITY

### 3.1 Authentication Flow

```
Launch App
    ↓
Check stored token in flutter_secure_storage
    ↓
Token exists? 
    ├─→ YES: validateToken() → AuthService
    │         ├─→ Valid: Load UserModel → AuthProvider → HomeScreen
    │         └─→ Invalid: Clear token → LoginScreen
    └─→ NO: Show LoginScreen
    
LoginScreen / RegisterScreen
    ├─→ loginWithEmailAndPassword(email, password)
    ├─→ register(email, password, firstName, lastName...)
    └─→ loginWithSocialMedia(provider: facebook|google|apple)
    
All paths:
    ├─→ MQTT request to stbf/auth/{request|register}
    ├─→ Server validates, returns user + token
    ├─→ Store token in flutter_secure_storage
    ├─→ Update AuthProvider.user
    └─→ Navigate to HomeScreen
```

### 3.2 Session Management

- **Token Storage:** `flutter_secure_storage` (platform-native secure storage)
- **Token Validation:** On app launch, on login, before API calls
- **Token Lifecycle:** Stored until explicit logout
- **Auto-login:** Enabled via token validation on startup
- **Logout:** Clear token from secure storage + clear AuthProvider

### 3.3 User Roles & Permissions

**Mentioned in UserModel:**
```dart
final List<String>? roles;  // e.g., ['volunteer', 'organizer', 'admin']

bool hasRole(String role) => roles?.contains(role) ?? false;
```

**Implied Role Types:**
- **Volunteer** - Standard user, can join projects, log hours
- **Organizer** - Can create/manage projects
- **Admin** - Platform management (implied)

**Permission System:** Managed server-side via MQTT Go Auth plugin based on database records

### 3.4 Data Security

- **Credentials:** Username, password sent via MQTT with authentication
- **Token Storage:** `flutter_secure_storage` (encrypted on platform level)
- **MQTT Connection:** Supports TLS in production (controlled by `kDebugMode`)
- **Secure Storage Keys:** 
  - `auth_token` - Session token
  - `mqtt_username`, `mqtt_password` - MQTT credentials
  - `mqtt_host`, `mqtt_port` - Connection config

---

## 4. CORE SERVICES ARCHITECTURE

### 4.1 Service Layer Pattern

All services follow a consistent pattern:

```dart
class SomeService {
  final MqttService _mqttService;
  static const String _requestTopic = 'stbf/feature/request';
  static const String _responseTopic = 'stbf/feature/response';
  
  SomeService(this._mqttService) {
    _init();
  }
  
  Future<void> _init() async {
    await _mqttService.subscribe(_responseTopic);
  }
  
  Future<ResultType> operation(...) async {
    try {
      final response = await _mqttService.request(
        _requestTopic,
        _responseTopic,
        {'action': 'operation_name', ...data}
      );
      
      if (response['status'] == 'success') {
        return ResultType.fromJson(response['data']);
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      throw Exception('Operation failed: $e');
    }
  }
}
```

### 4.2 Service Dependencies

```
MqttService (Foundation)
    ↓
AuthService
UserService
ProjectService
VolunteerService
RewardsService
    ↓
AuthProvider
UserProvider
ProjectProvider
RewardsProvider (custom ChangeNotifier)
VolunteerProvider (custom ChangeNotifier)
    ↓
Widgets
```

---

## 5. DATA MODELS & SERIALIZATION

### 5.1 Model Architecture

All models use `json_serializable` for JSON serialization:

```dart
@JsonSerializable()
class ModelName {
  // Fields
  final String id;
  
  // JSON factory
  factory ModelName.fromJson(Map<String, dynamic> json) => 
      _$ModelNameFromJson(json);
  
  // JSON serialization
  Map<String, dynamic> toJson() => _$ModelNameToJson(this);
  
  // Computed properties
  String get computedValue => ...;
  
  // Helper methods
  ModelName copyWith({...}) => ...;
}
```

Generated files: `*.g.dart` (created by `dart run build_runner build`)

### 5.2 Data Models by Feature

**Authentication Models:**
- `UserModel` - User profile (id, email, firstName, lastName, phoneNumber, location, profileImageUrl, bio, roles, isVerified, status, timestamps)
- `SkillModel` - User skill/interest (id, name, proficiency, category)

**Project Models:**
- `ProjectModel` - Service opportunity (id, title, description, organizerId, organizerName, location, geo-coordinates, dates, volunteer counts, requiredSkills, causeAreas, tags, status, pointsMultiplier, images, recurring)
- `ProjectSlotModel` - Time slot for project (id, projectId, startTime, endTime, maxVolunteers, registeredVolunteers, status)

**Volunteer Models:**
- `CommitmentModel` - Project registration (id, userId, projectId, commitmentDate, times, numberOfVolunteers, status, registeredAt)
- `ServiceRecordModel` - Service hours record (id, userId, projectId, serviceDate, times, hoursServed, pointsEarned, status, skills, verifiedBy, verifiedAt, notes)
- `TeamModel` - Volunteer team (id, name, description, focusAreas, members, createdAt, updatedAt)
- `TeamMemberModel` - Team membership (userId, role, joinedAt, contributions)

**Rewards Models:**
- `WalletModel` - User wallet (userId, stbfPoints, stbfPointsExpiringSoon, nextExpirationDate, servDRBalance, servCoinBalance, walletAddresses, servCoinWalletActivated)
- `PointsTransactionModel` - Points transaction (id, userId, type, amount, timestamp, description, projectId)
- `ServDRTransactionModel` - SERV DR conversion (id, userId, type, servDRAmount, pointsAmount, servCoinAmount, timestamp, exchangeRate)
- `RewardModel` - Marketplace reward (id, title, description, category, servDRCost, pointsCost, quantity, imageUrl, claimUrl, expirationDate)
- `RedemptionModel` - Claimed reward (id, userId, rewardId, claimedAt, fulfilledAt, status, claimCode, deliveryAddress)

### 5.3 Code Generation

**Setup:**
```bash
# Run once to generate all models
dart run build_runner build

# Watch mode for development
dart run build_runner watch

# Force regenerate (delete conflicts)
dart run build_runner build --delete-conflicting-outputs
```

**Dependencies:**
- `json_annotation: ^4.9.0`
- `json_serializable: ^6.8.0` (dev)
- `build_runner: ^2.3.3` (dev)

---

## 6. PLATFORM SUPPORT

### 6.1 Platform Configurations

**Supported Platforms:**
- iOS (native via Xcode)
- Android (native via Android Studio)
- macOS (desktop)
- Web (via Flutter Web)
- Windows/Linux (potential)

### 6.2 Android Configuration

**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
    <application
        android:label="serve_to_be_free"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            ...
        />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

**Features:**
- Material Design UI
- Text processing intents support
- Standard Flutter embedding (v2)

### 6.3 iOS Configuration

**File:** `ios/Runner/Info.plist`

- Standard Flutter app configuration
- Platform-specific native capabilities possible

### 6.4 Build Commands

```bash
# Android
flutter build apk              # Release APK
flutter build appbundle        # App Bundle for Play Store

# iOS
flutter build ios              # Build for iOS

# Desktop
flutter build macos            # macOS app
flutter build windows          # Windows app
flutter build linux            # Linux app

# Web
flutter build web              # Web deployment

# Debug/Release
flutter run --debug            # Debug mode
flutter run --release          # Release mode
```

---

## 7. UI/UX DESIGN

### 7.1 Theme System

**Location:** `lib/core/theme/app_theme.dart`

**Design System:**
- **Material Design 3** with dark theme preference
- **Google Fonts:** Inter typeface
- **Responsive:** Adapts to all screen sizes

**Color Palette:**

Primary Colors:
- Primary: `#4A7AFF` (Blue)
- Primary Light: `#91B4FF`
- Primary Dark: `#1E56CC`

Secondary Colors:
- Secondary: `#52C41A` (Green)
- Secondary Light: `#8AE354`
- Secondary Dark: `#2B8000`

Accent:
- Accent: `#FA8C16` (Orange)

Status Colors:
- Success: `#52C41A` (Green)
- Warning: `#FADB14` (Yellow)
- Error: `#F5222D` (Red)
- Info: `#1890FF` (Blue)

Background:
- Scaffold: `#121212` (Very Dark)
- Card: `#1E1E1E` (Dark)
- Surface: `#252525` (Dark)

Text:
- Primary: `#FFFFFF` (White)
- Secondary: `#B3B3B3` (Light Gray)
- Disabled: `#757575` (Medium Gray)

**Component Styling:**

Buttons:
- ElevatedButton: Full-width, 56px height, blue background
- OutlinedButton: 1.5px blue border, 56px height
- TextButton: Blue text foreground

Input Fields:
- Dark surface fill (`#252525`)
- No border when enabled
- Blue border (1.5px) when focused
- Rounded corners (8px)
- 16px horizontal padding, 18px vertical

Navigation:
- BottomNavigationBar: Dark background, blue selected items
- AppBar: Dark background, no elevation

### 7.2 Navigation Pattern

**Shell-Based Navigation:**

```
AuthWrapper
    ↓
isAuthenticated?
    ├─→ YES: HomeScreen (Shell)
    │   └─→ BottomNavigationBar
    │       ├─→ Tab 0: DashboardScreen
    │       ├─→ Tab 1: ProjectsScreen
    │       ├─→ Tab 2: CommunityScreen
    │       ├─→ Tab 3: RewardsScreen
    │       └─→ Tab 4: ProfileScreen
    │
    └─→ NO: LoginScreen
        ├─→ Register: RegisterScreen
        ├─→ Reset: ResetPasswordScreen
        └─→ Social Login: Via AuthService
```

**Detail Navigation:**
- Push via `Navigator.push(MaterialPageRoute(...))`
- Pop via `Navigator.pop(context)`
- No named routing (direct object passing)

**AppBar Actions:**
- Notifications icon (placeholder)
- Logout button

### 7.3 Responsive Design

The app is responsive across:
- Mobile phones (320dp+)
- Tablets (600dp+)
- Desktop (via Flutter Web)

Design patterns:
- Single column on phones
- Multi-column on larger screens (via Row/Column with Expanded)
- Grid layouts for quick actions (GridView)
- Adaptive bottom sheets
- Safe area insets handled

### 7.4 Screen Layouts

**DashboardScreen:**
- Welcome gradient card
- 2x2 grid of stat cards
- 3x2 quick action grid
- Recent activity list (3 items)
- Upcoming events list (2 items)

**ProfileScreen:**
- Header card with avatar
- Edit button
- 3-stat row (Projects, Hours, Points)
- Skills section with chips
- Recent service section

**CommunityScreen:**
- TabBar with 3 tabs
- Feed: Card-based activity stream
- Teams: List of team cards with join buttons
- Leaderboard: Podium + ranked list

**ProjectsScreen:**
- Search/filter bar
- Featured projects carousel (implied)
- Project grid/list view
- Infinite scroll with pagination

**RewardsScreen:**
- Wallet summary card
- Points conversion section
- Reward marketplace grid
- Transaction history

---

## 8. KEY DIFFERENCES FROM REACT PWA (serve/)

### 8.1 Architecture Differences

| Aspect | Flutter App | React PWA |
|--------|-------------|----------|
| Language | Dart | TypeScript/React |
| Backend | MQTT only | Supabase + Edge Functions |
| State Management | Provider | MobX + TanStack Query |
| Routing | Direct navigation | File-based (Generouted) |
| UI Framework | Material Design 3 | Ionic |
| Storage | Hive + Secure Storage | Browser storage |
| Build Target | Native mobile (iOS/Android/desktop) | Web-first PWA |

### 8.2 Feature Completeness Differences

**Flutter App (More Complete):**
- ✅ Multi-tier rewards system (Points → SERV DR → SERV Coin)
- ✅ Team management with invitations
- ✅ Service hour logging with verification
- ✅ Social community features (feed, leaderboard)
- ✅ Real-time MQTT communication
- ✅ Volunteer commitment tracking
- ✅ Skill-based project matching

**React PWA (Feature Set):**
- ✅ Project management and event scheduling
- ✅ Basic points system
- ✅ Real-time Supabase subscriptions
- ✅ Cross-platform PWA (web, iOS via Capacitor, Android via Capacitor)
- ✅ Focus on volunteer management workflows

### 8.3 Communication Protocol Differences

**Flutter App:**
- MQTT for all operations
- Request-response pattern with UUIDs
- Topic subscription model
- Stateful connection to broker

**React PWA:**
- REST APIs for operations
- Real-time subscriptions via Supabase
- Database-first approach
- Stateless HTTP requests

### 8.4 UI/UX Differences

**Flutter App:**
- Dark theme mandatory
- Native Material Design 3
- Optimized for touch
- Bottom tab navigation
- Mobile-first

**React PWA:**
- Light/dark theme support
- Ionic components
- Web-responsive design
- Tab/drawer navigation
- Web-first, responsive to mobile

---

## 9. DEVELOPMENT WORKFLOWS

### 9.1 Common Development Tasks

**Add New Screen:**
1. Create file in `lib/features/feature_name/screens/`
2. Extend StatelessWidget or StatefulWidget
3. Use Scaffold with AppBar
4. Access data via `Provider.of<T>(context)`

**Add New Feature:**
1. Create directory structure: `lib/features/new_feature/{screens,models,widgets}/`
2. Create models with @JsonSerializable
3. Create Service in `lib/core/services/`
4. Create Provider in `lib/core/providers/` (if needed)
5. Add Provider to main.dart MultiProvider list
6. Create screens
7. Add navigation

**Add New Data Model:**
1. Create `.dart` file in `lib/features/*/models/`
2. Annotate with `@JsonSerializable()`
3. Add `part '*.g.dart'`
4. Implement fromJson, toJson, copyWith
5. Run: `dart run build_runner build`

**Work with MQTT:**
```dart
// Inject service
final mqttService = Provider.of<MqttService>(context, listen: false);

// Use request-response pattern
final response = await mqttService.request(
  'stbf/feature/request',
  'stbf/feature/response',
  {'action': 'operation', 'data': ...}
);

if (response['status'] == 'success') {
  // Handle success
} else {
  // Handle error
}
```

**Update State:**
```dart
// Inject provider
final provider = Provider.of<SomeProvider>(context, listen: false);

// Call method to update state
await provider.fetchData();

// Widget automatically rebuilds when Provider notifies listeners
```

### 9.2 Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### 9.3 Code Analysis

```bash
# Analyze code for issues
flutter analyze

# Check for outdated dependencies
flutter pub outdated
```

### 9.4 Building & Deployment

**APK for Android:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**IPA for iOS:**
```bash
flutter build ios --release
# Output: build/ios/iphoneos/Runner.app
# Use Xcode to create .ipa
```

**Web:**
```bash
flutter build web --release
# Output: build/web/
```

---

## 10. DEPENDENCIES & VERSIONS

### 10.1 Core Dependencies

**Framework:**
- `flutter: sdk` (v3.7.2+)
- `cupertino_icons: ^1.0.8`

**State Management:**
- `provider: ^6.1.4`

**MQTT Communication:**
- `mqtt_client: ^10.0.0`

**Storage:**
- `flutter_secure_storage: ^9.2.4` (secure credentials)
- `hive_ce: 2.10.1` (local NoSQL DB)
- `hive_ce_flutter: 2.2.0` (Hive Flutter support)

**Serialization:**
- `json_annotation: ^4.9.0`
- `json_serializable: ^6.8.0` (dev)

**Utilities:**
- `uuid: ^4.5.1` (UUID generation)
- `google_fonts: ^6.2.1` (Typography)
- `intl: ^0.20.2` (Internationalization)
- `flutter_datetime_picker_plus: ^2.2.0` (Date/time selection)

**Code Generation:**
- `build_runner: ^2.3.3` (dev)
- `hive_ce_generator: 1.8.2` (dev)

**Other:**
- `extractor` (custom git dependency from tps-reports/extractor)

### 10.2 Custom Dependencies

**Extractor Package:**
```yaml
extractor:
  git:
    url: git@github.com:tps-reports/extractor.git
    ref: main
```
Purpose: TBD - appears to be internal utility package

### 10.3 Linting

- `flutter_lints: ^5.0.0` (dev)
- Configuration: `analysis_options.yaml`

---

## 11. CURRENT IMPLEMENTATION STATUS

### 11.1 Completed Features

- ✅ **Authentication** - Full login, registration, social login, password reset
- ✅ **MQTT Service** - Connection, publishing, request-response pattern
- ✅ **Project Browsing** - Search, filters, detailed views, registration
- ✅ **Dashboard** - Overview, quick actions, activity feeds
- ✅ **Profile Management** - User info, skills, service history
- ✅ **Rewards System** - Wallet, points, SERV DR, SERV Coin, redemptions
- ✅ **Team Management** - Create, join, invite, manage teams
- ✅ **Volunteer Commitments** - Register, track, cancel projects
- ✅ **Service Hour Logging** - Record hours, verification tracking
- ✅ **Community Features** - Feed (UI only), leaderboard, teams view

### 11.2 Partially Implemented / Stubs

- 🟡 **Community Feed** - UI present, service layer stub
- 🟡 **Notifications** - UI placeholder in AppBar
- 🟡 **Project Creation** - Screen present, service integration TBD
- 🟡 **Location-based Search** - Code present, integration TBD

### 11.3 Known Limitations / TODOs

- Web platform support (Flutter Web) - basic support, untested
- Offline caching - Hive structure present, not fully utilized
- Push notifications - Not implemented
- Image upload - Service layer present, UI integration incomplete
- Real-time updates - MQTT subscriptions present, streaming not fully utilized
- Biometric authentication - Not implemented (passkeys mentioned in CLAUDE.md as future)

---

## 12. IMPORTANT NOTES FOR DEVELOPERS

1. **MQTT is the only backend communication protocol** - No REST APIs, all operations go through MQTT

2. **Code Generation Required** - After model changes, run `dart run build_runner build`

3. **Secure Storage** - Always use `flutter_secure_storage` for sensitive data (tokens, credentials)

4. **Provider Pattern** - Use `Provider.of<T>(context, listen: false)` to get services, `listen: true` for reactive updates

5. **Error Handling** - All services throw exceptions, wrap calls in try-catch or handle in Provider methods

6. **State Rebuilding** - Use `notifyListeners()` in ChangeNotifier providers to trigger widget rebuilds

7. **Environment Configuration** - MQTT credentials configurable via secure storage, defaults to `dev.2h2.us:1883`

8. **Token Management** - AuthService handles token storage, retrieval, and validation automatically

9. **Platform-Specific Code** - Use conditional imports or platform channels for native features

10. **Testing** - Focus on service layer testing (MQTT mocking), Provider testing for state management

---

## 13. QUICK REFERENCE

### Project Structure
```
lib/
├── main.dart                    # App entry point, provider setup
├── code.dart                    # Code generation utilities
├── extract.dart                 # Extractor package utilities
├── core/
│   ├── services/               # Business logic (6 services)
│   ├── providers/              # State management (3 providers)
│   └── theme/                  # Theming (1 theme file)
└── features/
    ├── auth/                   # 3 screens, 2 models, 1 widget
    ├── home/                   # 2 screens
    ├── service_opportunities/  # 5 screens, 2 models, 3 widgets
    ├── volunteer_management/   # ~5 screens, 4 models
    ├── rewards/                # 9 screens, 5 models, 4 widgets
    ├── profile/                # 2 screens, 2 widgets
    └── community/              # 1 screen (complex tabbed UI)
```

### File Counts
- Screens: 29 total
- Models: 13 data models
- Services: 6 core services
- Providers: 5 state providers (3 standard, 2 custom ChangeNotifier)

### Lines of Code (Estimated)
- MQTT Service: ~280 LOC
- Auth Service: ~170 LOC
- Project Service: ~250 LOC
- Rewards Service: ~400 LOC (includes RewardsProvider)
- Volunteer Service: ~350 LOC (includes VolunteerProvider)
- Main dashboard: ~350 LOC
- Community screen: ~550 LOC

---

## 14. COMPARISON MATRIX: Flutter vs React PWA

| Dimension | Flutter App | React PWA | Winner |
|-----------|------------|----------|--------|
| Mobile UX | Native, optimized | Responsive PWA | Flutter |
| Web Support | Via Flutter Web | Native | React |
| Code Reuse | Single codebase | Separate web/mobile | Flutter |
| Real-time | MQTT push | Supabase subscriptions | Tied |
| Offline Support | Hive capable | Service workers | Tied |
| Developer Experience | Dart learning curve | TypeScript familiar | React |
| Performance | Compiled native | Web optimized | Flutter |
| Deployment | App stores | Hosting + PWA | React |
| Community Features | Implemented | Basic | Flutter |
| Rewards System | Full 3-tier | Basic points | Flutter |
| **Overall Recommendation** | **Better for mobile-first**  | **Better for web-first** | **Use both** |

---

## 15. APPENDICES

### A. MQTT Topics Summary

```
stbf/auth/{request,response}              - Authentication operations
stbf/register/{request,response}          - User registration
stbf/user/{request,response}              - User profile, skills, notifications
stbf/project/{request,response}           - Service opportunities
stbf/volunteer/{request,response}         - Commitments, service hours
stbf/team/{request,response}              - Team management
stbf/wallet/{request,response}            - Wallet, points, SERV DR transactions
stbf/rewards/{request,response}           - Reward marketplace, redemptions
stbf/community/{request,response}         - Social features (stub)
```

### B. Key Classes & Their Purposes

```
MqttService                 - MQTT broker connection & messaging
AuthService                 - Authentication & user session
UserService                 - User profile & preferences
ProjectService              - Service opportunities & projects
VolunteerService            - Commitments, hours, teams
RewardsService              - Wallet, rewards, conversions

AuthProvider                - Auth state for app-wide access
UserProvider                - User profile state
ProjectProvider             - Projects & search state
RewardsProvider             - Wallet & rewards state
VolunteerProvider           - Commitments & teams state

AppTheme                    - Material Design 3 dark theme
```

### C. Common Error Handling Patterns

```dart
// In Service
try {
  final response = await _mqttService.request(...);
  if (response['status'] == 'success') {
    return ResultType.fromJson(response['data']);
  } else {
    throw Exception(response['message'] ?? 'Operation failed');
  }
} catch (e) {
  throw Exception('Operation failed: $e');
}

// In Provider
try {
  _isLoading = true;
  notifyListeners();
  
  final result = await _service.operation();
  
  _isLoading = false;
  notifyListeners();
  return result;
} catch (e) {
  _isLoading = false;
  _errorMessage = e.toString();
  notifyListeners();
  rethrow;
}

// In Screen
try {
  await provider.fetchData();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

---

**Document Generated:** November 11, 2025
**Analysis Version:** 1.0
**Flutter SDK Version:** ^3.7.2
**Material Design:** Version 3

