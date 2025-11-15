import 'package:flutter_test/flutter_test.dart';
import 'package:serve_to_be_free/core/services/mqtt_service.dart';
import 'package:serve_to_be_free/core/services/offline_service.dart';
import 'package:serve_to_be_free/core/constants/mqtt_topics.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  group('Basic MQTT Integration Tests', () {
    setUpAll(() async {
      // Initialize Hive for testing
      TestWidgetsFlutterBinding.ensureInitialized();
      await Hive.initFlutter();
    });

    group('Service Initialization', () {
      test('Should create MqttService instance', () {
        final mqttService = MqttService();
        expect(mqttService, isNotNull);
        expect(mqttService.clientId, startsWith('stbf_app_'));
      });

      test('Should create OfflineService instance', () async {
        final offlineService = OfflineService();
        expect(offlineService, isNotNull);
        expect(offlineService.isOnline, isTrue);
        expect(offlineService.queueSize, equals(0));
      });
    });

    group('MQTT Topics', () {
      test('Should have correct topic structure', () {
        expect(MqttTopics.namespace, equals('stbf'));
        expect(MqttTopics.authRequest, equals('stbf/auth/request'));
        expect(MqttTopics.authResponse, equals('stbf/auth/response'));
        expect(MqttTopics.authRealtime, equals('stbf/auth/realtime'));

        expect(MqttTopics.userRequest, equals('stbf/user/request'));
        expect(MqttTopics.userResponse, equals('stbf/user/response'));
        expect(MqttTopics.userRealtime, equals('stbf/user/realtime'));

        expect(MqttTopics.projectRequest, equals('stbf/project/request'));
        expect(MqttTopics.projectResponse, equals('stbf/project/response'));
        expect(MqttTopics.projectRealtime, equals('stbf/project/realtime'));
      });

      test('Should generate dynamic topics correctly', () {
        final userId = 'user-123';
        expect(MqttTopics.userNotifications(userId), equals('stbf/notifications/user-123'));

        final teamId = 'team-456';
        expect(MqttTopics.teamChannel(teamId), equals('stbf/team/team-456/channel'));

        final projectId = 'proj-789';
        expect(MqttTopics.projectChannel(projectId), equals('stbf/project/proj-789/channel'));
      });

      test('Should identify STBF topics correctly', () {
        expect(MqttTopics.isStbfTopic('stbf/auth/request'), isTrue);
        expect(MqttTopics.isStbfTopic('other/topic'), isFalse);

        expect(MqttTopics.extractFeature('stbf/auth/request'), equals('auth'));
        expect(MqttTopics.extractAction('stbf/auth/request'), equals('request'));
      });
    });

    group('Offline Service', () {
      test('Should cache and retrieve data', () async {
        final offlineService = OfflineService();
        await offlineService.initialize();

        // Cache some data
        final testData = {'id': '123', 'name': 'Test'};
        await offlineService.cacheData('test_key', testData);

        // Retrieve cached data
        final retrieved = offlineService.getCachedData<Map>('test_key');
        expect(retrieved, isNotNull);
        expect(retrieved!['id'], equals('123'));
        expect(retrieved['name'], equals('Test'));

        // Cleanup
        await offlineService.clearAll();
      });

      test('Should queue operations when offline', () async {
        final offlineService = OfflineService();
        await offlineService.initialize();

        // Queue an operation
        final operationId = await offlineService.queueOperation(
          'create',
          {'table': 'projects', 'data': {'title': 'Test Project'}},
          priority: 1,
        );

        expect(operationId, isNotNull);
        expect(offlineService.queueSize, equals(1));
        expect(offlineService.pendingOperationsCount, equals(1));

        // Get pending operations
        final pending = await offlineService.getPendingOperations();
        expect(pending.length, equals(1));
        expect(pending[0]['operation'], equals('create'));

        // Cleanup
        await offlineService.clearAll();
      });

      test('Should provide cache statistics', () async {
        final offlineService = OfflineService();
        await offlineService.initialize();

        // Add some cache entries
        await offlineService.cacheData('key1', {'data': 'value1'});
        await offlineService.cacheData('key2', {'data': 'value2'});

        final stats = offlineService.getCacheStats();
        expect(stats['totalEntries'], greaterThan(0));
        expect(stats['isOnline'], isNotNull);

        // Cleanup
        await offlineService.clearAll();
      });

      test('Should clear cache by pattern', () async {
        final offlineService = OfflineService();
        await offlineService.initialize();

        // Add multiple cache entries
        await offlineService.cacheData('user_profile_123', {'name': 'User 1'});
        await offlineService.cacheData('user_profile_456', {'name': 'User 2'});
        await offlineService.cacheData('featured_projects', [{'id': '1'}]);

        // Clear user profile caches
        await offlineService.clearCache(pattern: 'user_profile');

        // Verify specific pattern was cleared
        expect(offlineService.getCachedData('user_profile_123'), isNull);
        expect(offlineService.getCachedData('user_profile_456'), isNull);
        expect(offlineService.getCachedData('featured_projects'), isNotNull);

        // Cleanup
        await offlineService.clearAll();
      });

      test('Should respect cache expiration', () async {
        final offlineService = OfflineService();
        await offlineService.initialize();

        // Cache data with short expiration
        await offlineService.cacheData(
          'temp_data',
          {'value': 'test'},
          expiration: Duration(milliseconds: 100),
        );

        // Verify data exists immediately
        expect(offlineService.getCachedData('temp_data'), isNotNull);

        // Wait for expiration
        await Future.delayed(Duration(milliseconds: 150));

        // Verify data expired
        expect(offlineService.getCachedData('temp_data'), isNull);

        // Cleanup
        await offlineService.clearAll();
      });
    });
  });
}