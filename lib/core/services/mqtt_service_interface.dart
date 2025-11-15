import 'dart:async';

/// Abstract interface for MQTT service to enable platform-specific implementations
abstract class IMqttService {
  /// Connection status
  bool get isConnected;

  /// Check if client is initialized
  bool get isInitialized;

  /// Client identifier
  String get clientId;

  /// Stream of incoming messages
  Stream<Map<String, dynamic>> get messageStream;

  /// Initialize the MQTT client
  Future<void> initialize();

  /// Reconnect if connection is lost
  Future<bool> reconnect();

  /// Subscribe to a topic
  Future<bool> subscribe(String topic, {int qos = 1});

  /// Publish a message to a topic
  Future<bool> publish(String topic, Map<String, dynamic> message, {int qos = 1});

  /// Request-response pattern with timeout
  Future<Map<String, dynamic>> request(
    String requestTopic,
    String responseTopic,
    Map<String, dynamic> message,
    {Duration timeout = const Duration(seconds: 30)}
  );

  /// Disconnect from the broker
  Future<void> disconnect();

  /// Dispose resources
  void dispose();
}
