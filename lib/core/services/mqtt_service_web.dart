import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import 'mqtt_service_interface.dart';

class MqttService implements IMqttService {
  // Logger for debug information
  final Logger _logger = Logger('MqttService');

  // MQTT Client instance - web browser client
  MqttClient? _client;

  // Secure storage for credentials
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Connection status
  bool _isConnected = false;
  @override
  bool get isConnected => _isConnected;

  // Stream controllers for message events
  final StreamController<Map<String, dynamic>> _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  @override
  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;

  // Topic mapping to track subscriptions and responses
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};

  // Client identifier
  final String _clientId = 'stbf_app_${const Uuid().v4()}';

  // Getter for client ID
  @override
  String get clientId => _clientId;

  // Initialize the MQTT client
  @override
  Future<void> initialize() async {
    try {
      // Get stored connection settings
      final host = await _secureStorage.read(key: 'mqtt_host') ?? 'dev.2h2.us';

      // For web, use WebSocket connection
      final wsPorts = ['8083', '9001', '8080'];
      final wsPort = await _secureStorage.read(key: 'mqtt_ws_port') ?? wsPorts[0];
      final wsUrl = 'ws://$host:$wsPort/mqtt';
      _logger.info('Connecting to WebSocket URL: $wsUrl');
      _client = MqttBrowserClient(wsUrl, _clientId);

      // Client configuration
      _client!
        ..keepAlivePeriod = 60
        ..autoReconnect = false  // Disable auto-reconnect for now to prevent blocking
        ..onConnected = _onConnected
        ..onDisconnected = _onDisconnected
        ..onSubscribed = _onSubscribed
        ..onSubscribeFail = _onSubscribeFail
        ..pongCallback = _pong;

      _client!.logging(on: false);

      // Set up message handler
      _client?.updates?.listen(_onMessage);

      // Try initial connection but don't wait for it to complete
      _connect().catchError((e) {
        _logger.warning('MQTT connection failed, continuing without real-time features: $e');
      });
    } catch (e) {
      _logger.severe('Failed to initialize MQTT service: $e');
    }
  }

  // Connect to MQTT broker
  Future<bool> _connect() async {
    try {
      final username = await _secureStorage.read(key: 'mqtt_username') ?? 'datastore';
      final password = await _secureStorage.read(key: 'mqtt_password') ?? 'all4Datastore!';

      final connMessage = MqttConnectMessage()
        ..withClientIdentifier(_clientId)
        ..withWillTopic('willTopic')
        ..withWillMessage('Disconnected unexpectedly')
        ..withWillQos(MqttQos.atLeastOnce)
        ..withWillRetain()
        ..startClean();

      _client?.connectionMessage = connMessage;

      if (username.isNotEmpty && password.isNotEmpty) {
        _client?.connectionMessage?.authenticateAs(username, password);
      }

      await _client?.connect();
      return _isConnected;
    } catch (e) {
      _logger.severe('Connection failed: $e');
      _isConnected = false;
      return false;
    }
  }

  // Check if client is initialized
  @override
  bool get isInitialized => _client != null;

  // Reconnect if connection is lost
  @override
  Future<bool> reconnect() async {
    if (!isInitialized) {
      _logger.warning('Cannot reconnect: MQTT client not initialized');
      return false;
    }

    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      return true;
    }

    try {
      await _client?.connect();
      return _isConnected;
    } catch (e) {
      _logger.severe('Reconnection failed: $e');
      return false;
    }
  }

  // Subscribe to a topic
  @override
  Future<bool> subscribe(String topic, {int qos = 1}) async {
    if (!isInitialized) {
      _logger.warning('Cannot subscribe: MQTT client not initialized');
      return false;
    }

    if (!_isConnected && !await reconnect()) {
      _logger.warning('Cannot subscribe to $topic: Not connected and reconnection failed');
      return false;
    }

    try {
      _client?.subscribe(topic, MqttQos.values[qos]);
      return true;
    } catch (e) {
      _logger.severe('Failed to subscribe to $topic: $e');
      return false;
    }
  }

  // Publish a message to a topic
  @override
  Future<bool> publish(String topic, Map<String, dynamic> message, {int qos = 1}) async {
    if (!isInitialized) {
      _logger.warning('Cannot publish: MQTT client not initialized');
      return false;
    }

    if (!_isConnected && !await reconnect()) {
      _logger.warning('Cannot publish to $topic: Not connected and reconnection failed');
      return false;
    }

    try {
      _client?.publishMessage(
        topic,
        MqttQos.values[qos],
        MqttClientPayloadBuilder().addUTF8String(json.encode(message)).payload!,
        retain: false
      );
      return true;
    } catch (e) {
      _logger.severe('Failed to publish to $topic: $e');
      return false;
    }
  }

  // Request-response pattern with timeout
  @override
  Future<Map<String, dynamic>> request(
    String requestTopic,
    String responseTopic,
    Map<String, dynamic> message,
    {Duration timeout = const Duration(seconds: 30)}
  ) async {
    if (!isInitialized) {
      throw Exception('MQTT client not initialized - operating in offline mode');
    }

    if (!_isConnected && !await reconnect()) {
      throw Exception('Not connected to MQTT broker - operating in offline mode');
    }

    // Generate a unique request ID
    final requestId = const Uuid().v4();
    message['requestId'] = requestId;

    // Subscribe to response topic if not already subscribed
    await subscribe(responseTopic);

    // Create a completer to handle the async response
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;

    // Publish the request
    await publish(requestTopic, message);

    // Set up timeout
    Timer(timeout, () {
      if (!completer.isCompleted) {
        _pendingRequests.remove(requestId);
        completer.completeError(
          Exception('Request timed out after ${timeout.inSeconds} seconds')
        );
      }
    });

    // Wait for response
    return completer.future;
  }

  // Disconnect from the broker
  @override
  Future<void> disconnect() async {
    _client?.disconnect();
  }

  // Connection callback
  void _onConnected() {
    _isConnected = true;
    _logger.info('Connected to MQTT broker');
  }

  // Disconnection callback
  void _onDisconnected() {
    _isConnected = false;
    _logger.warning('Disconnected from MQTT broker');
  }

  // Subscription callback
  void _onSubscribed(String topic) {
    _logger.info('Subscribed to topic: $topic');
  }

  // Subscription failure callback
  void _onSubscribeFail(String topic) {
    _logger.severe('Failed to subscribe to topic: $topic');
  }

  // Ping response callback
  void _pong() {
    _logger.fine('Ping response received');
  }

  // Message handler
  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (var message in messages) {
      final recMess = message.payload as MqttPublishMessage;
      final payload = utf8.decode(recMess.payload.message);

      try {
        final data = json.decode(payload) as Map<String, dynamic>;

        // Check if this is a response to a pending request
        if (data.containsKey('requestId') && _pendingRequests.containsKey(data['requestId'])) {
          final completer = _pendingRequests.remove(data['requestId'])!;
          completer.complete(data);
        } else {
          // Broadcast message to all listeners
          _messageStreamController.add(data);
        }
      } catch (e) {
        _logger.warning('Failed to parse message: $e');
      }
    }
  }

  // Dispose resources
  @override
  void dispose() {
    _client?.disconnect();
    _messageStreamController.close();
  }
}
