import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'mqtt_service.dart';
import 'supabase_service.dart';
import 'offline_service.dart';

/// Helper function to deeply convert Map<dynamic, dynamic> to Map<String, dynamic>
Map<String, dynamic> _deepConvertMap(dynamic data) {
  if (data == null) {
    return {};
  }

  if (data is! Map) {
    throw ArgumentError('Data must be a Map, got ${data.runtimeType}');
  }

  return Map<String, dynamic>.fromEntries(
    data.entries.map((entry) {
      final key = entry.key.toString();
      final value = entry.value;

      if (value is Map) {
        return MapEntry(key, _deepConvertMap(value));
      } else if (value is List) {
        return MapEntry(key, value.map((item) {
          if (item is Map) {
            return _deepConvertMap(item);
          }
          return item;
        }).toList());
      } else {
        return MapEntry(key, value);
      }
    }),
  );
}

/// Hybrid Data Service that combines Supabase for persistent storage
/// and MQTT for real-time updates.
///
/// This service provides:
/// - Data persistence via Supabase
/// - Real-time updates via MQTT
/// - Offline support with queuing
/// - Automatic sync between both systems
class HybridDataService {
  final MqttService _mqttService;
  final SupabaseService _supabaseService;
  final OfflineService _offlineService;

  // MQTT Topics for real-time events
  static const String _baseEventTopic = 'stbf/events';
  static const String _baseDataTopic = 'stbf/data';

  // Stream controllers for hybrid events
  final _hybridEventController = StreamController<HybridEvent>.broadcast();
  Stream<HybridEvent> get events => _hybridEventController.stream;

  // Track active subscriptions
  final Map<String, StreamSubscription> _subscriptions = {};

  HybridDataService({
    required MqttService mqttService,
    required SupabaseService supabaseService,
    required OfflineService offlineService,
  })  : _mqttService = mqttService,
        _supabaseService = supabaseService,
        _offlineService = offlineService {
    _initialize();
  }

  void _initialize() {
    // Listen to MQTT messages and convert to hybrid events
    _mqttService.messageStream.listen(_handleMqttMessage);
  }

  /// Create operation - Store in Supabase and notify via MQTT
  Future<T> create<T>({
    required String table,
    required Map<String, dynamic> data,
    T Function(Map<String, dynamic>)? fromJson,
    bool broadcast = true,
  }) async {
    try {
      // Store in Supabase
      final result = await _supabaseService.create<T>(
        table,
        data,
        fromJson: fromJson,
      );

      // Broadcast via MQTT if enabled
      if (broadcast) {
        await _broadcastEvent(
          type: HybridEventType.created,
          table: table,
          data: fromJson != null ? (result as dynamic).toJson() : result as Map<String, dynamic>,
        );
      }

      return result;
    } catch (e) {
      // If online operation fails, queue for later
      if (!await _isOnline()) {
        await _offlineService.queueOperation(
          'create',
          {
            'table': table,
            'data': data,
          },
        );
        // Return optimistic result
        if (fromJson != null) {
          return fromJson(data);
        }
        return data as T;
      }
      rethrow;
    }
  }

  /// Read operation - Try cache first, then Supabase
  Future<List<T>> read<T>({
    required String table,
    Map<String, dynamic>? filters,
    String? orderBy,
    int? limit,
    T Function(Map<String, dynamic>)? fromJson,
    bool useCache = true,
  }) async {
    // Check cache first if enabled
    if (useCache) {
      final cacheKey = _getCacheKey(table, filters);
      final cached = _offlineService.getCachedData<List<dynamic>>(cacheKey);
      if (cached != null) {
        if (fromJson != null) {
          return cached.map((item) => fromJson(_deepConvertMap(item))).toList();
        }
        // Deep convert each item in the list
        return cached.map((item) => _deepConvertMap(item) as T).toList();
      }
    }

    try {
      // Fetch from Supabase
      final result = await _supabaseService.read<T>(
        table,
        filters: filters,
        orderBy: orderBy,
        limit: limit,
        fromJson: fromJson,
      );

      // Cache the result
      if (useCache) {
        final cacheKey = _getCacheKey(table, filters);
        final dataToCache = fromJson != null
            ? result.map((item) => (item as dynamic).toJson()).toList()
            : result;
        await _offlineService.cacheData(cacheKey, dataToCache);
      }

      return result;
    } catch (e) {
      // Return cached data on error
      final cacheKey = _getCacheKey(table, filters);
      final cached = _offlineService.getCachedData<List<dynamic>>(cacheKey);
      if (cached != null) {
        if (fromJson != null) {
          return cached.map((item) => fromJson(_deepConvertMap(item))).toList();
        }
        // Deep convert each item in the list
        return cached.map((item) => _deepConvertMap(item) as T).toList();
      }
      rethrow;
    }
  }

  /// Update operation - Update Supabase and notify via MQTT
  Future<T> update<T>({
    required String table,
    required String id,
    required Map<String, dynamic> data,
    T Function(Map<String, dynamic>)? fromJson,
    bool broadcast = true,
  }) async {
    try {
      // Update in Supabase
      final result = await _supabaseService.update<T>(
        table,
        id,
        data,
        fromJson: fromJson,
      );

      // Broadcast via MQTT if enabled
      if (broadcast) {
        await _broadcastEvent(
          type: HybridEventType.updated,
          table: table,
          data: {
            'id': id,
            ...fromJson != null ? (result as dynamic).toJson() : result as Map<String, dynamic>,
          },
        );
      }

      return result;
    } catch (e) {
      // Queue for offline sync
      if (!await _isOnline()) {
        await _offlineService.queueOperation(
          'update',
          {
            'table': table,
            'id': id,
            'data': data,
          },
        );
        // Return optimistic result
        if (fromJson != null) {
          return fromJson({...data, 'id': id});
        }
        return data as T;
      }
      rethrow;
    }
  }

  /// Delete operation - Delete from Supabase and notify via MQTT
  Future<void> delete({
    required String table,
    required String id,
    bool broadcast = true,
  }) async {
    try {
      // Delete from Supabase
      await _supabaseService.delete(table, id);

      // Broadcast via MQTT if enabled
      if (broadcast) {
        await _broadcastEvent(
          type: HybridEventType.deleted,
          table: table,
          data: {'id': id},
        );
      }
    } catch (e) {
      // Queue for offline sync
      if (!await _isOnline()) {
        await _offlineService.queueOperation(
          'delete',
          {
            'table': table,
            'id': id,
          },
        );
      } else {
        rethrow;
      }
    }
  }

  /// Subscribe to real-time updates for a table
  void subscribeToTable({
    required String table,
    required Function(HybridEvent) onEvent,
  }) {
    // Subscribe to MQTT topic for this table
    final topic = '$_baseDataTopic/$table';
    _mqttService.subscribe(topic);

    // Filter events for this table
    final subscription = events
        .where((event) => event.table == table)
        .listen(onEvent);

    _subscriptions[table] = subscription;
  }

  /// Unsubscribe from table updates
  void unsubscribeFromTable(String table) {
    _subscriptions[table]?.cancel();
    _subscriptions.remove(table);
  }

  /// Execute RPC/stored procedure
  Future<T> rpc<T>({
    required String functionName,
    Map<String, dynamic>? params,
    bool broadcast = true,
  }) async {
    final result = await _supabaseService.rpc<T>(
      functionName,
      params: params,
    );

    if (broadcast) {
      await _broadcastEvent(
        type: HybridEventType.rpc,
        table: functionName,
        data: params ?? {},
      );
    }

    return result;
  }

  /// Broadcast an event via MQTT
  Future<void> _broadcastEvent({
    required HybridEventType type,
    required String table,
    required Map<String, dynamic> data,
  }) async {
    final topic = '$_baseDataTopic/$table';
    final message = {
      'type': type.toString(),
      'table': table,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'clientId': _mqttService.clientId,
    };

    await _mqttService.publish(topic, message);

    // Also emit to local stream
    _hybridEventController.add(HybridEvent(
      type: type,
      table: table,
      data: data,
    ));
  }

  /// Handle incoming MQTT messages
  void _handleMqttMessage(Map<String, dynamic> message) {
    // Parse MQTT message into HybridEvent
    if (message['type'] != null && message['table'] != null) {
      final event = HybridEvent(
        type: HybridEventType.values.firstWhere(
          (e) => e.toString() == message['type'],
          orElse: () => HybridEventType.unknown,
        ),
        table: message['table'],
        data: message['data'] ?? {},
      );

      // Don't process our own messages
      if (message['clientId'] != _mqttService.clientId) {
        _hybridEventController.add(event);
      }
    }
  }

  /// Send notification via MQTT
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    String? message,
    Map<String, dynamic>? data,
  }) async {
    final topic = 'stbf/notifications/$userId';
    await _mqttService.publish(topic, {
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Subscribe to notifications for a user
  Future<void> subscribeToNotifications(String userId) async {
    final topic = 'stbf/notifications/$userId';
    await _mqttService.subscribe(topic);
  }

  /// Sync offline queue
  Future<void> syncOfflineQueue() async {
    final operations = await _offlineService.getPendingOperations();

    for (final op in operations) {
      try {
        switch (op['operation']) {
          case 'create':
            await create(
              table: op['data']['table'],
              data: op['data']['data'],
              broadcast: false, // Don't broadcast synced ops
            );
            break;
          case 'update':
            await update(
              table: op['data']['table'],
              id: op['data']['id'],
              data: op['data']['data'],
              broadcast: false,
            );
            break;
          case 'delete':
            await delete(
              table: op['data']['table'],
              id: op['data']['id'],
              broadcast: false,
            );
            break;
        }

        // Remove from queue on success
        await _offlineService.removeOperation(op['id']);
      } catch (e) {
        debugPrint('Failed to sync operation: $e');
      }
    }
  }

  /// Check if online
  Future<bool> _isOnline() async {
    return _mqttService.isConnected && _supabaseService.client.auth.currentSession != null;
  }

  /// Generate cache key
  String _getCacheKey(String table, Map<String, dynamic>? filters) {
    final filterString = filters?.entries
        .map((e) => '${e.key}:${e.value}')
        .join('_') ?? '';
    return 'cache_${table}_$filterString';
  }

  /// Clean up
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _hybridEventController.close();
  }
}

/// Event types for hybrid system
enum HybridEventType {
  created,
  updated,
  deleted,
  rpc,
  notification,
  presence,
  unknown,
}

/// Hybrid event that combines Supabase and MQTT events
class HybridEvent {
  final HybridEventType type;
  final String table;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  HybridEvent({
    required this.type,
    required this.table,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}