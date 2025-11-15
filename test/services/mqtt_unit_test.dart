import 'package:flutter_test/flutter_test.dart';
import 'package:serve_to_be_free/core/services/mqtt_service.dart';
import 'package:serve_to_be_free/core/constants/mqtt_topics.dart';

void main() {
  group('MQTT Unit Tests', () {
    group('MqttService', () {
      test('Should generate unique client ID', () {
        final service1 = MqttService();
        final service2 = MqttService();

        expect(service1.clientId, isNotEmpty);
        expect(service2.clientId, isNotEmpty);
        expect(service1.clientId, isNot(equals(service2.clientId)));
        expect(service1.clientId, startsWith('stbf_app_'));
        expect(service2.clientId, startsWith('stbf_app_'));
      });

      test('Should track connection status', () {
        final service = MqttService();
        expect(service.isConnected, isFalse);
      });

      test('Should provide message stream', () {
        final service = MqttService();
        expect(service.messageStream, isNotNull);
      });
    });

    group('MQTT Topics Configuration', () {
      test('Should have correct namespace', () {
        expect(MqttTopics.namespace, equals('stbf'));
      });

      test('Should define authentication topics', () {
        expect(MqttTopics.authRequest, equals('stbf/auth/request'));
        expect(MqttTopics.authResponse, equals('stbf/auth/response'));
        expect(MqttTopics.authRealtime, equals('stbf/auth/realtime'));
        expect(MqttTopics.authLogout, equals('stbf/auth/logout'));
      });

      test('Should define user management topics', () {
        expect(MqttTopics.userRequest, equals('stbf/user/request'));
        expect(MqttTopics.userResponse, equals('stbf/user/response'));
        expect(MqttTopics.userRealtime, equals('stbf/user/realtime'));
        expect(MqttTopics.userPresence, equals('stbf/user/presence'));
      });

      test('Should define project management topics', () {
        expect(MqttTopics.projectRequest, equals('stbf/project/request'));
        expect(MqttTopics.projectResponse, equals('stbf/project/response'));
        expect(MqttTopics.projectRealtime, equals('stbf/project/realtime'));
        expect(MqttTopics.projectUpdates, equals('stbf/project/updates'));
      });

      test('Should define volunteer management topics', () {
        expect(MqttTopics.volunteerRequest, equals('stbf/volunteer/request'));
        expect(MqttTopics.volunteerResponse, equals('stbf/volunteer/response'));
        expect(MqttTopics.volunteerRealtime, equals('stbf/volunteer/realtime'));
        expect(MqttTopics.teamUpdates, equals('stbf/team/updates'));
      });

      test('Should define service hours topics', () {
        expect(MqttTopics.hoursRequest, equals('stbf/hours/request'));
        expect(MqttTopics.hoursResponse, equals('stbf/hours/response'));
        expect(MqttTopics.hoursRealtime, equals('stbf/hours/realtime'));
        expect(MqttTopics.hoursApproval, equals('stbf/hours/approval'));
      });

      test('Should define rewards topics', () {
        expect(MqttTopics.rewardsRequest, equals('stbf/rewards/request'));
        expect(MqttTopics.rewardsResponse, equals('stbf/rewards/response'));
        expect(MqttTopics.rewardsRealtime, equals('stbf/rewards/realtime'));
        expect(MqttTopics.pointsUpdate, equals('stbf/points/update'));
      });

      test('Should define social features topics', () {
        expect(MqttTopics.socialRequest, equals('stbf/social/request'));
        expect(MqttTopics.socialResponse, equals('stbf/social/response'));
        expect(MqttTopics.socialRealtime, equals('stbf/social/realtime'));
        expect(MqttTopics.feedUpdates, equals('stbf/feed/updates'));
        expect(MqttTopics.messageChannel, equals('stbf/message/channel'));
      });

      test('Should define QR code topics', () {
        expect(MqttTopics.qrScan, equals('stbf/qr/scan'));
        expect(MqttTopics.qrValidate, equals('stbf/qr/validate'));
        expect(MqttTopics.qrCheckIn, equals('stbf/qr/checkin'));
      });

      test('Should define currency/blockchain topics', () {
        expect(MqttTopics.currencyRequest, equals('stbf/currency/request'));
        expect(MqttTopics.currencyResponse, equals('stbf/currency/response'));
        expect(MqttTopics.currencyConversion, equals('stbf/currency/conversion'));
        expect(MqttTopics.blockchainSync, equals('stbf/blockchain/sync'));
      });
    });

    group('Dynamic Topic Generation', () {
      test('Should generate user-specific topics', () {
        const userId = 'user-123';
        expect(MqttTopics.userNotifications(userId),
               equals('stbf/notifications/user-123'));
        expect(MqttTopics.userMessages(userId),
               equals('stbf/messages/user-123'));
        expect(MqttTopics.userAlerts(userId),
               equals('stbf/alerts/user-123'));
      });

      test('Should generate team-specific topics', () {
        const teamId = 'team-456';
        expect(MqttTopics.teamChannel(teamId),
               equals('stbf/team/team-456/channel'));
        expect(MqttTopics.teamNotifications(teamId),
               equals('stbf/team/team-456/notifications'));
      });

      test('Should generate project-specific topics', () {
        const projectId = 'proj-789';
        expect(MqttTopics.projectChannel(projectId),
               equals('stbf/project/proj-789/channel'));
        expect(MqttTopics.projectVolunteers(projectId),
               equals('stbf/project/proj-789/volunteers'));
        expect(MqttTopics.projectCheckIn(projectId),
               equals('stbf/project/proj-789/checkin'));
      });
    });

    group('Topic Helper Methods', () {
      test('Should generate topic pairs', () {
        final topics = MqttTopics.getTopicPair('test');
        expect(topics['request'], equals('stbf/test/request'));
        expect(topics['response'], equals('stbf/test/response'));
      });

      test('Should generate feature topics', () {
        final topics = MqttTopics.getFeatureTopics('profile');
        expect(topics['request'], equals('stbf/profile/request'));
        expect(topics['response'], equals('stbf/profile/response'));
        expect(topics['realtime'], equals('stbf/profile/realtime'));
      });

      test('Should identify STBF topics', () {
        expect(MqttTopics.isStbfTopic('stbf/auth/request'), isTrue);
        expect(MqttTopics.isStbfTopic('stbf/user/response'), isTrue);
        expect(MqttTopics.isStbfTopic('other/topic'), isFalse);
        expect(MqttTopics.isStbfTopic('mqtt/test'), isFalse);
      });

      test('Should extract feature from topic', () {
        expect(MqttTopics.extractFeature('stbf/auth/request'), equals('auth'));
        expect(MqttTopics.extractFeature('stbf/user/response'), equals('user'));
        expect(MqttTopics.extractFeature('stbf/project/realtime'), equals('project'));
        expect(MqttTopics.extractFeature('other/topic'), isNull);
      });

      test('Should extract action from topic', () {
        expect(MqttTopics.extractAction('stbf/auth/request'), equals('request'));
        expect(MqttTopics.extractAction('stbf/user/response'), equals('response'));
        expect(MqttTopics.extractAction('stbf/project/realtime'), equals('realtime'));
        expect(MqttTopics.extractAction('other/topic'), isNull);
      });
    });

    group('MQTT Message Types', () {
      test('Should define request types', () {
        expect(MqttMessageType.create, equals('create'));
        expect(MqttMessageType.read, equals('read'));
        expect(MqttMessageType.update, equals('update'));
        expect(MqttMessageType.delete, equals('delete'));
        expect(MqttMessageType.list, equals('list'));
        expect(MqttMessageType.search, equals('search'));
      });

      test('Should define response types', () {
        expect(MqttMessageType.success, equals('success'));
        expect(MqttMessageType.error, equals('error'));
        expect(MqttMessageType.partial, equals('partial'));
        expect(MqttMessageType.timeout, equals('timeout'));
      });

      test('Should define event types', () {
        expect(MqttMessageType.created, equals('created'));
        expect(MqttMessageType.updated, equals('updated'));
        expect(MqttMessageType.deleted, equals('deleted'));
        expect(MqttMessageType.connected, equals('connected'));
        expect(MqttMessageType.disconnected, equals('disconnected'));
      });

      test('Should define notification types', () {
        expect(MqttMessageType.info, equals('info'));
        expect(MqttMessageType.warning, equals('warning'));
        expect(MqttMessageType.alert, equals('alert'));
        expect(MqttMessageType.reminder, equals('reminder'));
      });
    });

    group('MQTT QoS Levels', () {
      test('Should define QoS levels', () {
        expect(MqttQoSLevel.atMostOnce, equals(0));
        expect(MqttQoSLevel.atLeastOnce, equals(1));
        expect(MqttQoSLevel.exactlyOnce, equals(2));
      });

      test('Should define recommended QoS for operations', () {
        expect(MqttQoSLevel.defaultQoS, equals(1));
        expect(MqttQoSLevel.criticalQoS, equals(2));
        expect(MqttQoSLevel.notificationQoS, equals(1));
        expect(MqttQoSLevel.analyticsQoS, equals(0));
      });
    });
  });
}