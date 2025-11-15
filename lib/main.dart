import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:serve_to_be_free/core/config/environment.dart';
import 'package:serve_to_be_free/core/services/supabase_service.dart';
import 'package:serve_to_be_free/core/services/mqtt_service.dart';
import 'package:serve_to_be_free/core/services/offline_service.dart';
import 'package:serve_to_be_free/core/services/hybrid_data_service.dart';
import 'package:serve_to_be_free/core/services/auth_service.dart';
import 'package:serve_to_be_free/core/services/user_service.dart';
import 'package:serve_to_be_free/core/services/project_service.dart';
import 'package:serve_to_be_free/core/services/rewards_service_supabase.dart';
import 'package:serve_to_be_free/core/providers/auth_provider.dart';
import 'package:serve_to_be_free/core/providers/user_provider.dart';
import 'package:serve_to_be_free/core/providers/project_provider.dart';
import 'package:serve_to_be_free/core/theme/app_theme.dart';
import 'package:serve_to_be_free/features/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate environment configuration
  Environment.validate();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize MQTT
  final mqttService = MqttService();
  await mqttService.initialize();

  // Initialize offline service
  final offlineService = OfflineService();
  await offlineService.initialize();

  // Initialize hybrid data service
  final hybridDataService = HybridDataService(
    mqttService: mqttService,
    supabaseService: SupabaseService.instance,
    offlineService: offlineService,
  );

  // Set up offline sync callback
  offlineService.onConnectionRestored = () {
    hybridDataService.syncOfflineQueue();
  };

  // Initialize auth service
  final authService = AuthService();

  // Initialize other services with hybrid approach
  final userService = UserService(
    mqttService: mqttService,
    hybridDataService: hybridDataService,
    offlineService: offlineService,
  );

  final projectService = ProjectService(
    mqttService: mqttService,
    hybridDataService: hybridDataService,
    offlineService: offlineService,
  );

  final rewardsService = RewardsServiceSupabase();

  runApp(MainApp(
    mqttService: mqttService,
    offlineService: offlineService,
    hybridDataService: hybridDataService,
    authService: authService,
    userService: userService,
    projectService: projectService,
    rewardsService: rewardsService,
  ));
}

class MainApp extends StatelessWidget {
  final MqttService mqttService;
  final OfflineService offlineService;
  final HybridDataService hybridDataService;
  final AuthService authService;
  final UserService userService;
  final ProjectService projectService;
  final RewardsServiceSupabase rewardsService;

  const MainApp({
    super.key,
    required this.mqttService,
    required this.offlineService,
    required this.hybridDataService,
    required this.authService,
    required this.userService,
    required this.projectService,
    required this.rewardsService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services
        Provider<MqttService>.value(value: mqttService),
        ChangeNotifierProvider<OfflineService>.value(value: offlineService),
        Provider<HybridDataService>.value(value: hybridDataService),
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<UserService>.value(value: userService),
        Provider<ProjectService>.value(value: projectService),
        Provider<RewardsServiceSupabase>.value(value: rewardsService),

        // Feature providers
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (context) => UserProvider(
            userService,
            context.read<AuthProvider>(),
          ),
          update: (context, auth, previous) =>
            UserProvider(userService, auth, previous?.user),
        ),
        ChangeNotifierProvider(
          create: (_) => ProjectProvider(projectService),
        ),
        ChangeNotifierProvider(
          create: (_) => RewardsProviderSupabase(rewardsService),
        ),
      ],
      child: MaterialApp(
        title: 'Serve To Be Free',
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
