import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Offline service for caching data and queuing operations
///
/// This service provides:
/// - Local caching with Hive
/// - Operation queue for offline sync
/// - Automatic sync when connection restored
/// - Conflict resolution
class OfflineService extends ChangeNotifier {
  late Box<dynamic> _cacheBox;
  late Box<Map> _queueBox;
  late Box<dynamic> _metadataBox;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Sync callback
  Function()? onConnectionRestored;

  /// Initialize offline service
  Future<void> initialize() async {
    // Open Hive boxes
    _cacheBox = await Hive.openBox('offline_cache');
    _queueBox = await Hive.openBox<Map>('sync_queue');
    _metadataBox = await Hive.openBox('metadata');

    // Check initial connectivity
    final connectivityResults = await _connectivity.checkConnectivity();
    _isOnline = !connectivityResults.contains(ConnectivityResult.none) &&
                connectivityResults.isNotEmpty;

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline;
    _isOnline = !results.contains(ConnectivityResult.none) && results.isNotEmpty;

    if (wasOffline && _isOnline) {
      // Connection restored
      debugPrint('Connection restored - syncing offline data');
      onConnectionRestored?.call();
    }

    notifyListeners();
  }

  /// Cache data with expiration
  Future<void> cacheData(
    String key,
    dynamic data, {
    Duration? expiration,
  }) async {
    final cacheEntry = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiration': expiration?.inMilliseconds,
    };

    await _cacheBox.put(key, cacheEntry);
  }

  /// Get cached data
  T? getCachedData<T>(
    String key, {
    Duration maxAge = const Duration(hours: 24),
  }) {
    final cached = _cacheBox.get(key);
    if (cached == null) return null;

    final timestamp = cached['timestamp'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;

    // Check if expired by age
    if (age > maxAge.inMilliseconds) {
      _cacheBox.delete(key);
      return null;
    }

    // Check custom expiration
    final expiration = cached['expiration'] as int?;
    if (expiration != null && age > expiration) {
      _cacheBox.delete(key);
      return null;
    }

    return cached['data'] as T;
  }

  /// Clear cache for specific pattern
  Future<void> clearCache({String? pattern}) async {
    if (pattern == null) {
      await _cacheBox.clear();
    } else {
      final keys = _cacheBox.keys
          .where((key) => key.toString().contains(pattern))
          .toList();
      await _cacheBox.deleteAll(keys);
    }
  }

  /// Queue an operation for later sync
  Future<String> queueOperation(
    String operation,
    Map<String, dynamic> data, {
    int priority = 0,
  }) async {
    final id = const Uuid().v4();
    final queueEntry = {
      'id': id,
      'operation': operation,
      'data': data,
      'priority': priority,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
      'status': 'pending',
    };

    await _queueBox.put(id, queueEntry);
    return id;
  }

  /// Get pending operations sorted by priority and timestamp
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final operations = _queueBox.values
        .where((op) => op['status'] == 'pending')
        .toList();

    operations.sort((a, b) {
      // Sort by priority first (higher priority first)
      final priorityCompare = (b['priority'] as int).compareTo(a['priority'] as int);
      if (priorityCompare != 0) return priorityCompare;

      // Then by timestamp (older first)
      return (a['timestamp'] as int).compareTo(b['timestamp'] as int);
    });

    return operations.cast<Map<String, dynamic>>();
  }

  /// Remove operation from queue
  Future<void> removeOperation(String id) async {
    await _queueBox.delete(id);
  }

  /// Mark operation as failed
  Future<void> markOperationFailed(String id, {String? error}) async {
    final operation = _queueBox.get(id);
    if (operation != null) {
      operation['status'] = 'failed';
      operation['error'] = error;
      operation['retryCount'] = (operation['retryCount'] ?? 0) + 1;
      await _queueBox.put(id, operation);
    }
  }

  /// Retry failed operations
  Future<void> retryFailedOperations({int maxRetries = 3}) async {
    final failedOps = _queueBox.values
        .where((op) =>
          op['status'] == 'failed' &&
          (op['retryCount'] ?? 0) < maxRetries
        )
        .toList();

    for (final op in failedOps) {
      op['status'] = 'pending';
      await _queueBox.put(op['id'], op);
    }
  }

  /// Get queue size
  int get queueSize => _queueBox.length;

  /// Get pending operations count
  int get pendingOperationsCount =>
    _queueBox.values.where((op) => op['status'] == 'pending').length;

  /// Save metadata
  Future<void> saveMetadata(String key, dynamic value) async {
    await _metadataBox.put(key, value);
  }

  /// Get metadata
  T? getMetadata<T>(String key) {
    return _metadataBox.get(key) as T?;
  }

  /// Check if data needs refresh
  bool needsRefresh(String key, {Duration maxAge = const Duration(hours: 1)}) {
    final cached = _cacheBox.get(key);
    if (cached == null) return true;

    final timestamp = cached['timestamp'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;

    return age > maxAge.inMilliseconds;
  }

  /// Batch cache operations
  Future<void> batchCache(Map<String, dynamic> items) async {
    final entries = items.entries.map((e) => {
      'data': e.value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }).toList();

    await _cacheBox.putAll(Map.fromIterables(
      items.keys,
      entries,
    ));
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final totalSize = _cacheBox.length;
    final oldestEntry = _cacheBox.values.isEmpty
      ? null
      : _cacheBox.values
          .map((e) => e['timestamp'] as int)
          .reduce((a, b) => a < b ? a : b);

    return {
      'totalEntries': totalSize,
      'queueSize': queueSize,
      'pendingOperations': pendingOperationsCount,
      'oldestEntry': oldestEntry != null
        ? DateTime.fromMillisecondsSinceEpoch(oldestEntry)
        : null,
      'isOnline': _isOnline,
    };
  }

  /// Clear old cache entries
  Future<void> pruneCache({Duration maxAge = const Duration(days: 7)}) async {
    final cutoff = DateTime.now().millisecondsSinceEpoch - maxAge.inMilliseconds;
    final keysToDelete = <dynamic>[];

    for (final key in _cacheBox.keys) {
      final entry = _cacheBox.get(key);
      if (entry != null && entry['timestamp'] != null) {
        final timestamp = entry['timestamp'] as int;
        if (timestamp < cutoff) {
          keysToDelete.add(key);
        }
      }
    }

    await _cacheBox.deleteAll(keysToDelete);
    debugPrint('Pruned ${keysToDelete.length} old cache entries');
  }

  /// Export queue for debugging
  List<Map<String, dynamic>> exportQueue() {
    return _queueBox.values.toList().cast<Map<String, dynamic>>();
  }

  /// Import queue (for testing/migration)
  Future<void> importQueue(List<Map<String, dynamic>> operations) async {
    for (final op in operations) {
      if (op['id'] != null) {
        await _queueBox.put(op['id'], op);
      }
    }
  }

  /// Clear everything
  Future<void> clearAll() async {
    await _cacheBox.clear();
    await _queueBox.clear();
    await _metadataBox.clear();
  }

  /// Dispose
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}