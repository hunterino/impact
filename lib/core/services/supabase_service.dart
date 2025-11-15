import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';

/// Singleton service for managing Supabase client
///
/// This service provides centralized access to the Supabase client
/// and common database operations.
class SupabaseService {
  static SupabaseService? _instance;
  late final SupabaseClient client;

  /// Private constructor for singleton pattern
  SupabaseService._() {
    client = Supabase.instance.client;
  }

  /// Get singleton instance
  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  /// Initialize Supabase
  /// This should be called once in main.dart
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
      storageOptions: const StorageClientOptions(
        retryAttempts: 3,
      ),
    );
  }

  /// Generic CRUD Operations

  /// Create a new record
  Future<T> create<T>(
    String table,
    Map<String, dynamic> data, {
    String columns = '*',
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await client.from(table).insert(data).select(columns).single();

    if (fromJson != null) {
      return fromJson(response);
    }
    return response as T;
  }

  /// Read records with optional filters
  Future<List<T>> read<T>(
    String table, {
    String columns = '*',
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    var query = client.from(table).select(columns);

    // Apply filters first (returns PostgrestFilterBuilder)
    if (filters != null) {
      filters.forEach((key, value) {
        if (value is List) {
          query = query.inFilter(key, value);
        } else if (value is Map && value.containsKey('\$gte')) {
          query = query.gte(key, value['\$gte']);
        } else if (value is Map && value.containsKey('\$lte')) {
          query = query.lte(key, value['\$lte']);
        } else {
          query = query.eq(key, value);
        }
      });
    }

    // Now apply transformations (ordering, pagination)
    dynamic transformQuery = query;

    // Apply ordering
    if (orderBy != null) {
      transformQuery = transformQuery.order(orderBy, ascending: ascending);
    }

    // Apply pagination
    if (limit != null) {
      transformQuery = transformQuery.limit(limit);
    }
    if (offset != null && limit != null) {
      transformQuery = transformQuery.range(offset, offset + limit - 1);
    }

    final response = await transformQuery;

    if (fromJson != null) {
      return (response as List).map((item) => fromJson(item)).toList();
    }
    return (response as List).cast<T>();
  }

  /// Get a single record by ID
  Future<T> getById<T>(
    String table,
    String id, {
    String columns = '*',
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await client.from(table).select(columns).eq('id', id).single();

    if (fromJson != null) {
      return fromJson(response);
    }
    return response as T;
  }

  /// Update a record
  Future<T> update<T>(
    String table,
    String id,
    Map<String, dynamic> data, {
    String columns = '*',
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await client
        .from(table)
        .update(data)
        .eq('id', id)
        .select(columns)
        .single();

    if (fromJson != null) {
      return fromJson(response);
    }
    return response as T;
  }

  /// Delete a record
  Future<void> delete(String table, String id) async {
    await client.from(table).delete().eq('id', id);
  }

  /// Delete multiple records
  Future<void> deleteWhere(String table, Map<String, dynamic> filters) async {
    var query = client.from(table).delete();

    filters.forEach((key, value) {
      query = query.eq(key, value);
    });

    await query;
  }

  /// Execute a stored procedure / RPC
  Future<T> rpc<T>(
    String functionName, {
    Map<String, dynamic>? params,
  }) async {
    final response = await client.rpc(functionName, params: params);
    return response as T;
  }

  /// Full-text search
  Future<List<T>> search<T>(
    String table,
    String column,
    String query, {
    String columns = '*',
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await client.from(table).select(columns).textSearch(column, query);

    if (fromJson != null) {
      return (response as List).map((item) => fromJson(item)).toList();
    }
    return (response as List).cast<T>();
  }

  /// Upsert (insert or update)
  Future<T> upsert<T>(
    String table,
    Map<String, dynamic> data, {
    String columns = '*',
    String? onConflict,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final response = await client
        .from(table)
        .upsert(data, onConflict: onConflict)
        .select(columns)
        .single();

    if (fromJson != null) {
      return fromJson(response);
    }
    return response as T;
  }

  /// Count records
  Future<int> count(
    String table, {
    Map<String, dynamic>? filters,
  }) async {
    var query = client.from(table).select('id');

    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }

    final response = await query;
    return (response as List).length;
  }

  /// Storage Operations

  /// Upload file to storage
  Future<String> uploadFile(
    String bucket,
    String path,
    List<int> bytes, {
    String? contentType,
  }) async {
    await client.storage.from(bucket).uploadBinary(
      path,
      Uint8List.fromList(bytes),
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: true,
      ),
    );

    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Download file from storage
  Future<List<int>> downloadFile(String bucket, String path) async {
    final response = await client.storage.from(bucket).download(path);
    return response;
  }

  /// Delete file from storage
  Future<void> deleteFile(String bucket, String path) async {
    await client.storage.from(bucket).remove([path]);
  }

  /// Get public URL for file
  String getPublicUrl(String bucket, String path) {
    return client.storage.from(bucket).getPublicUrl(path);
  }

  /// Real-time Subscriptions

  /// Subscribe to table changes
  RealtimeChannel subscribeToTable(
    String table, {
    required void Function(PostgresChangePayload) onInsert,
    required void Function(PostgresChangePayload) onUpdate,
    required void Function(PostgresChangePayload) onDelete,
    String schema = 'public',
  }) {
    return client
        .channel('${table}_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: schema,
          table: table,
          callback: onInsert,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: schema,
          table: table,
          callback: onUpdate,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: schema,
          table: table,
          callback: onDelete,
        )
        .subscribe();
  }

  /// Subscribe to specific record changes
  RealtimeChannel subscribeToRecord(
    String table,
    String id, {
    required void Function(PostgresChangePayload) onUpdate,
    required void Function(PostgresChangePayload) onDelete,
    String schema = 'public',
  }) {
    return client
        .channel('${table}_${id}_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: schema,
          table: table,
          callback: (payload) {
            if (payload.newRecord['id'] == id) {
              onUpdate(payload);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: schema,
          table: table,
          callback: (payload) {
            if (payload.oldRecord['id'] == id) {
              onDelete(payload);
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to presence (who's online)
  RealtimeChannel subscribeToPresence(
    String channelName, {
    required void Function(dynamic) onSync,
    required void Function(dynamic) onJoin,
    required void Function(dynamic) onLeave,
  }) {
    return client
        .channel(channelName)
        .onPresenceSync(onSync)
        .onPresenceJoin(onJoin)
        .onPresenceLeave(onLeave)
        .subscribe();
  }

  /// Send broadcast message
  Future<void> sendBroadcast(
    String channelName,
    String event,
    Map<String, dynamic> payload,
  ) async {
    // In newer Supabase API, use sendBroadcastMessage method
    final channel = client.channel(channelName);
    await channel.subscribe();
    await channel.sendBroadcastMessage(
      event: event,
      payload: payload,
    );
  }

  /// Unsubscribe from channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await channel.unsubscribe();
  }

  /// Helper method to handle errors
  T handleError<T>(dynamic error, T defaultValue) {
    print('Supabase Error: $error');
    return defaultValue;
  }
}