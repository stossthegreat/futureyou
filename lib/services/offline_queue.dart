import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

part 'offline_queue.g.dart';

@HiveType(typeId: 4)
class QueuedRequest extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String endpoint;

  @HiveField(2)
  String method; // POST, GET, PUT, DELETE

  @HiveField(3)
  String bodyJson; // Stored as JSON string

  @HiveField(4)
  int retryCount;

  @HiveField(5)
  DateTime queuedAt;

  @HiveField(6)
  DateTime? lastAttemptAt;

  QueuedRequest({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.bodyJson,
    this.retryCount = 0,
    required this.queuedAt,
    this.lastAttemptAt,
  });

  Map<String, dynamic> get body => jsonDecode(bodyJson);
}

class OfflineQueue {
  static const String _boxName = 'offline_queue';
  late Box<QueuedRequest> _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<QueuedRequest>(_boxName);
    _initialized = true;
    debugPrint('✓ Offline queue initialized');
  }

  /// Add a request to the queue
  Future<void> enqueue({
    required String endpoint,
    required String method,
    required Map<String, dynamic> body,
  }) async {
    if (!_initialized) await init();

    final id = '${DateTime.now().millisecondsSinceEpoch}_${endpoint.hashCode}';
    final request = QueuedRequest(
      id: id,
      endpoint: endpoint,
      method: method,
      bodyJson: jsonEncode(body),
      queuedAt: DateTime.now(),
    );

    await _box.put(id, request);
    debugPrint('📥 Queued offline request: $method $endpoint');
  }

  /// Get all pending requests
  List<QueuedRequest> getPending() {
    if (!_initialized) return [];
    return _box.values.toList()
      ..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
  }

  /// Get count of pending requests
  int getPendingCount() {
    if (!_initialized) return 0;
    return _box.length;
  }

  /// Mark request as processed and remove from queue
  Future<void> markProcessed(String requestId) async {
    if (!_initialized) return;
    await _box.delete(requestId);
    debugPrint('✓ Removed processed request: $requestId');
  }

  /// Update retry count
  Future<void> incrementRetry(String requestId) async {
    if (!_initialized) return;
    final request = _box.get(requestId);
    if (request != null) {
      request.retryCount++;
      request.lastAttemptAt = DateTime.now();
      await request.save();
    }
  }

  /// Remove old requests (older than 7 days or exceeded max retries)
  Future<void> cleanup({int maxRetries = 10, Duration maxAge = const Duration(days: 7)}) async {
    if (!_initialized) return;

    final now = DateTime.now();
    final toDelete = <String>[];

    for (final request in _box.values) {
      if (request.retryCount >= maxRetries ||
          now.difference(request.queuedAt) > maxAge) {
        toDelete.add(request.id);
      }
    }

    for (final id in toDelete) {
      await _box.delete(id);
    }

    if (toDelete.isNotEmpty) {
      debugPrint('🗑️ Cleaned up ${toDelete.length} old requests');
    }
  }

  /// Clear all pending requests
  Future<void> clearAll() async {
    if (!_initialized) return;
    await _box.clear();
    debugPrint('🗑️ Cleared all offline requests');
  }

  /// Get requests for a specific endpoint
  List<QueuedRequest> getByEndpoint(String endpoint) {
    if (!_initialized) return [];
    return _box.values.where((r) => r.endpoint == endpoint).toList();
  }
}

final offlineQueue = OfflineQueue();

