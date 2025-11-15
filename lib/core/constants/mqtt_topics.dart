/// MQTT Topic Constants
///
/// Centralized definition of all MQTT topics used in the application
/// Following the 5x platform pattern: stbf/{feature}/{action}
///
/// Topic Structure:
/// - Request topics: Used for client requests to backend
/// - Response topics: Used for backend responses to client
/// - Realtime topics: Used for real-time event broadcasting
/// - Notification topics: User-specific notification channels

class MqttTopics {
  // Base namespace for all STBF topics
  static const String namespace = 'stbf';

  // Authentication Topics
  static const String authRequest = '$namespace/auth/request';
  static const String authResponse = '$namespace/auth/response';
  static const String authRealtime = '$namespace/auth/realtime';
  static const String authLogout = '$namespace/auth/logout';

  // User Management Topics
  static const String userRequest = '$namespace/user/request';
  static const String userResponse = '$namespace/user/response';
  static const String userRealtime = '$namespace/user/realtime';
  static const String userPresence = '$namespace/user/presence';

  // Project Management Topics
  static const String projectRequest = '$namespace/project/request';
  static const String projectResponse = '$namespace/project/response';
  static const String projectRealtime = '$namespace/project/realtime';
  static const String projectUpdates = '$namespace/project/updates';

  // Volunteer Management Topics
  static const String volunteerRequest = '$namespace/volunteer/request';
  static const String volunteerResponse = '$namespace/volunteer/response';
  static const String volunteerRealtime = '$namespace/volunteer/realtime';
  static const String teamUpdates = '$namespace/team/updates';

  // Service Hours Topics
  static const String hoursRequest = '$namespace/hours/request';
  static const String hoursResponse = '$namespace/hours/response';
  static const String hoursRealtime = '$namespace/hours/realtime';
  static const String hoursApproval = '$namespace/hours/approval';

  // Rewards & Points Topics
  static const String rewardsRequest = '$namespace/rewards/request';
  static const String rewardsResponse = '$namespace/rewards/response';
  static const String rewardsRealtime = '$namespace/rewards/realtime';
  static const String pointsUpdate = '$namespace/points/update';

  // Survey Topics
  static const String surveyRequest = '$namespace/survey/request';
  static const String surveyResponse = '$namespace/survey/response';
  static const String surveyRealtime = '$namespace/survey/realtime';
  static const String surveySubmission = '$namespace/survey/submission';

  // Social Features Topics
  static const String socialRequest = '$namespace/social/request';
  static const String socialResponse = '$namespace/social/response';
  static const String socialRealtime = '$namespace/social/realtime';
  static const String feedUpdates = '$namespace/feed/updates';
  static const String messageChannel = '$namespace/message/channel';

  // Notification Topics (user-specific)
  static String userNotifications(String userId) => '$namespace/notifications/$userId';
  static String userMessages(String userId) => '$namespace/messages/$userId';
  static String userAlerts(String userId) => '$namespace/alerts/$userId';

  // Team Topics (team-specific)
  static String teamChannel(String teamId) => '$namespace/team/$teamId/channel';
  static String teamNotifications(String teamId) => '$namespace/team/$teamId/notifications';

  // Project Topics (project-specific)
  static String projectChannel(String projectId) => '$namespace/project/$projectId/channel';
  static String projectVolunteers(String projectId) => '$namespace/project/$projectId/volunteers';
  static String projectCheckIn(String projectId) => '$namespace/project/$projectId/checkin';

  // Event Management Topics
  static const String eventRequest = '$namespace/event/request';
  static const String eventResponse = '$namespace/event/response';
  static const String eventRealtime = '$namespace/event/realtime';
  static const String eventReminders = '$namespace/event/reminders';

  // Admin Topics
  static const String adminRequest = '$namespace/admin/request';
  static const String adminResponse = '$namespace/admin/response';
  static const String adminBroadcast = '$namespace/admin/broadcast';
  static const String systemAlerts = '$namespace/system/alerts';

  // Analytics Topics
  static const String analyticsRequest = '$namespace/analytics/request';
  static const String analyticsResponse = '$namespace/analytics/response';
  static const String analyticsRealtime = '$namespace/analytics/realtime';

  // File Upload Topics
  static const String uploadRequest = '$namespace/upload/request';
  static const String uploadResponse = '$namespace/upload/response';
  static const String uploadProgress = '$namespace/upload/progress';

  // QR Code Topics
  static const String qrScan = '$namespace/qr/scan';
  static const String qrValidate = '$namespace/qr/validate';
  static const String qrCheckIn = '$namespace/qr/checkin';

  // Currency/Blockchain Topics
  static const String currencyRequest = '$namespace/currency/request';
  static const String currencyResponse = '$namespace/currency/response';
  static const String currencyConversion = '$namespace/currency/conversion';
  static const String blockchainSync = '$namespace/blockchain/sync';

  // Helper methods for dynamic topic generation

  /// Generate a request-response topic pair for a feature
  static Map<String, String> getTopicPair(String feature) {
    return {
      'request': '$namespace/$feature/request',
      'response': '$namespace/$feature/response',
    };
  }

  /// Generate all topics for a feature (request, response, realtime)
  static Map<String, String> getFeatureTopics(String feature) {
    return {
      'request': '$namespace/$feature/request',
      'response': '$namespace/$feature/response',
      'realtime': '$namespace/$feature/realtime',
    };
  }

  /// Check if a topic belongs to STBF namespace
  static bool isStbfTopic(String topic) {
    return topic.startsWith(namespace);
  }

  /// Extract feature from topic
  static String? extractFeature(String topic) {
    if (!isStbfTopic(topic)) return null;
    final parts = topic.split('/');
    if (parts.length >= 2) {
      return parts[1];
    }
    return null;
  }

  /// Extract action from topic
  static String? extractAction(String topic) {
    if (!isStbfTopic(topic)) return null;
    final parts = topic.split('/');
    if (parts.length >= 3) {
      return parts[2];
    }
    return null;
  }
}

/// MQTT Message Types for standardized message handling
class MqttMessageType {
  // Request types
  static const String create = 'create';
  static const String read = 'read';
  static const String update = 'update';
  static const String delete = 'delete';
  static const String list = 'list';
  static const String search = 'search';

  // Response types
  static const String success = 'success';
  static const String error = 'error';
  static const String partial = 'partial';
  static const String timeout = 'timeout';

  // Event types
  static const String created = 'created';
  static const String updated = 'updated';
  static const String deleted = 'deleted';
  static const String connected = 'connected';
  static const String disconnected = 'disconnected';
  static const String subscribed = 'subscribed';
  static const String unsubscribed = 'unsubscribed';

  // Notification types
  static const String info = 'info';
  static const String warning = 'warning';
  static const String alert = 'alert';
  static const String reminder = 'reminder';
}

/// MQTT QoS Levels
class MqttQoSLevel {
  static const int atMostOnce = 0;   // Fire and forget
  static const int atLeastOnce = 1;  // Guaranteed delivery
  static const int exactlyOnce = 2;  // Guaranteed single delivery

  // Recommended QoS for different operations
  static const int defaultQoS = atLeastOnce;
  static const int criticalQoS = exactlyOnce;
  static const int notificationQoS = atLeastOnce;
  static const int analyticsQoS = atMostOnce;
}