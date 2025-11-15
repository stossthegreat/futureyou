import 'dart:async';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/coach_message.dart' as model;
import 'api_client.dart';

class MessagesService {
  static const String _boxName = 'coach_messages';
  static const String _deletedBoxName = 'deleted_message_ids';
  late Box<model.CoachMessage> _box;
  late Box<String> _deletedBox; // Track deleted message IDs
  bool _initialized = false;
  
  // Sync state
  DateTime? _lastSyncTime;
  bool _isSyncing = false;
  String? _lastSyncError;
  
  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 2);

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<model.CoachMessage>(_boxName);
    _deletedBox = await Hive.openBox<String>(_deletedBoxName);
    _initialized = true;
  }
  
  // Sync status getters
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isSyncing => _isSyncing;
  String? get lastSyncError => _lastSyncError;

  /// Get all messages sorted by date (newest first)
  List<model.CoachMessage> getAllMessages() {
    if (!_initialized) return [];
    final messages = _box.values
        .cast<model.CoachMessage>()
        .where((msg) => !_deletedBox.containsKey(msg.id)) // Filter out deleted
        .toList();
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return messages;
  }

  /// Get unread message count
  int getUnreadCount() {
    if (!_initialized) return 0;
    return _box.values
        .cast<model.CoachMessage>()
        .where((msg) => !msg.isRead && !_deletedBox.containsKey(msg.id))
        .length;
  }

  /// Get messages by kind
  List<model.CoachMessage> getMessagesByKind(model.MessageKind kind) {
    if (!_initialized) return [];
    final messages = _box.values
        .cast<model.CoachMessage>()
        .where((msg) => msg.kind == kind && !_deletedBox.containsKey(msg.id)) // Filter deleted
        .toList();
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return messages;
  }

  /// Mark message as read (local only - backend doesn't track read status)
  Future<void> markAsRead(String messageId) async {
    if (!_initialized) return;
    final message = _box.get(messageId);
    if (message != null) {
      message.isRead = true;
      await message.save();
      debugPrint('✓ Message marked as read: $messageId');
      // Update app badge
      await _updateAppBadge();
    }
  }

  /// Mark ALL messages as read (clears badge)
  Future<void> markAllAsRead() async {
    if (!_initialized) return;
    debugPrint('🔔 Marking all messages as read...');
    final messages = _box.values.cast<model.CoachMessage>().toList();
    for (final message in messages) {
      if (!message.isRead) {
        message.isRead = true;
        await message.save();
      }
    }
    debugPrint('✅ Marked ${messages.length} messages as read');
    // Update app badge to 0
    await _updateAppBadge();
  }

  /// Update app icon badge with unread count
  /// Uses flutter_local_notifications for cross-platform badge support
  Future<void> _updateAppBadge() async {
    try {
      final count = getUnreadCount();
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      if (count > 0) {
        // On Android, we'll show a persistent notification with the count
        // On iOS, badge is set via notification payload
        if (Platform.isAndroid) {
          // Android: Use notification badge (requires Android 8.0+)
          const androidDetails = AndroidNotificationDetails(
            'messages_channel',
            'Messages',
            channelDescription: 'Notifications for new messages',
            importance: Importance.low,
            priority: Priority.low,
            showWhen: false,
            number: null, // Badge count (Android doesn't support well)
          );
          const notificationDetails = NotificationDetails(android: androidDetails);
          // Note: Android app badge support is limited, mainly works on Samsung/Xiaomi launchers
        } else if (Platform.isIOS) {
          // iOS: Badge is better supported, can be set directly
          // This requires proper notification permissions
        }
        debugPrint('📱 App badge would show: $count (limited platform support)');
      }
    } catch (e) {
      debugPrint('⚠️ App badge not supported on this device: $e');
    }
  }

  /// Fetch latest messages from backend with retry logic
  Future<bool> syncMessages(String userId, {int retryCount = 0}) async {
    if (!_initialized) await init();
    if (_isSyncing) {
      debugPrint('⏭️ Sync already in progress, skipping');
      return false;
    }
    
    _isSyncing = true;
    _lastSyncError = null;
    
    try {
      debugPrint('🔄 Syncing messages from backend (attempt ${retryCount + 1})...');
      
      final result = await ApiClient.getCoachMessages();
      
      if (result.success && result.data != null) {
        // Convert API CoachMessage to model CoachMessage and store in Hive
        for (final apiMessage in result.data!) {
          // Skip if message was deleted locally
          if (_deletedBox.containsKey(apiMessage.id)) {
            debugPrint('⏭️ Skipping deleted message: ${apiMessage.id}');
            continue;
          }
          
          final existing = _box.get(apiMessage.id);
          
          // Convert to model
          final message = model.CoachMessage(
            id: apiMessage.id,
            userId: apiMessage.userId,
            kind: _convertKind(apiMessage.kind),
            title: apiMessage.title,
            body: apiMessage.body,
            meta: apiMessage.meta,
            createdAt: apiMessage.createdAt,
            isRead: existing?.isRead ?? false, // Preserve local read status
          );
          
          await _box.put(message.id, message);
        }
        
        _lastSyncTime = DateTime.now();
        _isSyncing = false;
        debugPrint('✅ Synced ${result.data!.length} messages');
        // Update app badge after syncing
        await _updateAppBadge();
        return true;
      } else {
        // Handle backend errors gracefully
        final errorMsg = result.error ?? 'Unknown error';
        if (errorMsg.contains('500')) {
          debugPrint('⚠️ Backend error (user may not exist yet) - app will work offline');
          _lastSyncError = 'Backend initializing...';
        } else {
          _lastSyncError = errorMsg;
        }
        throw Exception(errorMsg);
      }
    } on SocketException {
      _lastSyncError = 'No internet connection';
      debugPrint('❌ Sync failed: No internet connection');
      _isSyncing = false;
      
      // Retry with exponential backoff
      if (retryCount < _maxRetries) {
        final delay = _initialRetryDelay * (1 << retryCount);
        debugPrint('⏱️ Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
        return await syncMessages(userId, retryCount: retryCount + 1);
      }
      return false;
    } on TimeoutException {
      _lastSyncError = 'Request timed out';
      debugPrint('❌ Sync failed: Timeout');
      _isSyncing = false;
      
      // Retry
      if (retryCount < _maxRetries) {
        final delay = _initialRetryDelay * (1 << retryCount);
        await Future.delayed(delay);
        return await syncMessages(userId, retryCount: retryCount + 1);
      }
      return false;
    } catch (e) {
      _lastSyncError = e.toString();
      debugPrint('❌ Sync failed: $e');
      _isSyncing = false;
      
      // Don't retry 500 errors (backend issue, not network issue)
      if (e.toString().contains('500')) {
        debugPrint('⚠️ Backend error - skipping retries. App works offline.');
        return false;
      }
      
      // Retry for transient errors
      if (retryCount < _maxRetries) {
        final delay = _initialRetryDelay * (1 << retryCount);
        await Future.delayed(delay);
        return await syncMessages(userId, retryCount: retryCount + 1);
      }
      return false;
    }
  }

  /// Convert API MessageKind to model MessageKind
  model.MessageKind _convertKind(CoachMessageKind apiKind) {
    switch (apiKind) {
      case CoachMessageKind.brief:
        return model.MessageKind.brief;
      case CoachMessageKind.nudge:
        return model.MessageKind.nudge;
      case CoachMessageKind.mirror:
        return model.MessageKind.debrief;
      case CoachMessageKind.letter:
        return model.MessageKind.letter;
    }
  }

  /// Get today's morning brief
  model.CoachMessage? getTodaysBrief() {
    if (!_initialized) return null;
    
    final today = DateTime.now();
    final briefs = getMessagesByKind(model.MessageKind.brief);
    
    for (final brief in briefs) {
      if (brief.createdAt.year == today.year &&
          brief.createdAt.month == today.month &&
          brief.createdAt.day == today.day) {
        return brief;
      }
    }
    return null;
  }

  /// Get today's active nudge (latest unread)
  model.CoachMessage? getActiveNudge() {
    if (!_initialized) return null;
    
    final nudges = getMessagesByKind(model.MessageKind.nudge);
    final unreadNudges = nudges.where((n) => !n.isRead).toList();
    
    if (unreadNudges.isEmpty) return null;
    return unreadNudges.first; // Already sorted by date
  }

  /// Get yesterday's or today's debrief
  model.CoachMessage? getLatestDebrief() {
    if (!_initialized) return null;
    
    final debriefs = getMessagesByKind(model.MessageKind.debrief);
    if (debriefs.isEmpty) return null;
    return debriefs.first;
  }

  /// Get unread letters (weekly emotional letters)
  List<model.CoachMessage> getUnreadLetters() {
    if (!_initialized) return [];
    
    final letters = getMessagesByKind(model.MessageKind.letter);
    return letters.where((letter) => !letter.isRead).toList();
  }

  /// Add a new message (for testing or offline mode)
  Future<void> addMessage(model.CoachMessage message) async {
    if (!_initialized) await init();
    await _box.put(message.id, message);
  }

  /// Clear all messages
  Future<void> clearAll() async {
    if (!_initialized) return;
    await _box.clear();
  }

  /// Delete a specific message
  Future<void> deleteMessage(String messageId) async {
    debugPrint('🗑️ deleteMessage called for: $messageId');
    debugPrint('🗑️ _initialized: $_initialized');
    if (!_initialized) {
      debugPrint('🗑️ Not initialized, calling init()');
      await init();
      debugPrint('🗑️ init() completed');
    }
    debugPrint('🗑️ Box length before delete: ${_box.length}');
    debugPrint('🗑️ Message exists in box: ${_box.containsKey(messageId)}');
    
    // Delete from messages box
    await _box.delete(messageId);
    
    // Track deletion permanently so it won't come back from backend
    await _deletedBox.put(messageId, messageId);
    
    debugPrint('🗑️ Box length after delete: ${_box.length}');
    debugPrint('🗑️ Message still exists: ${_box.containsKey(messageId)}');
    debugPrint('🗑️ Deleted message: $messageId (tracked in deleted list)');
  }
}

final messagesService = MessagesService();

