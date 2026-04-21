import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import 'firestore_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// NotificationService
//
// Wires up Firebase Cloud Messaging on the client:
//   - requests permission (iOS + Android 13+)
//   - saves the device FCM token on the user's Firestore document
//   - listens for token refresh
//   - handles foreground, background, and terminated-app message taps
//   - deep-links to the chat room when a match/message notification is tapped
//
// Data payloads emitted by Cloud Functions look like:
//   type=match    matchId,otherUserId,otherUserName,otherUserPhoto
//   type=message  matchId,senderId,senderName,senderPhoto
// ═══════════════════════════════════════════════════════════════════════════

/// Background handler must be a top-level function.
/// Triggered when a data-only message arrives while the app is terminated or
/// backgrounded. We don't do much here — the OS shows the notification and
/// taps are re-delivered via [FirebaseMessaging.onMessageOpenedApp].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally left blank: server sends `notification` payloads so Android
  // renders the banner itself. Any heavy work would require re-initializing
  // Firebase here.
  if (kDebugMode) debugPrint('[FCM/bg] received ${message.messageId}');
}

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'roomr_notifications',
  'Roomr notifications',
  description: 'Matches and messages',
  importance: Importance.high,
);

class NotificationService {
  NotificationService(this._ref);

  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Called once per authenticated session. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _handleDeepLinkFromMatchId(payload);
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await requestPermission();

    final token = await _fcm.getToken();
    if (token != null) {
      await _ref.read(firestoreServiceProvider).saveFcmToken(token);
    }

    _fcm.onTokenRefresh.listen((newToken) {
      _ref.read(firestoreServiceProvider).saveFcmToken(newToken);
    });

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // App launched from a terminated state via a notification tap.
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) _onMessageOpenedApp(initialMessage);
  }

  Future<NotificationSettings> requestPermission() {
    return _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  /// Removes this device's token from Firestore before sign-out.
  Future<void> clearTokenForCurrentUser() async {
    final token = await _fcm.getToken();
    if (token == null) return;
    try {
      await _ref.read(firestoreServiceProvider).removeFcmToken(token);
    } catch (_) {
      // sign-out proceeds even if token cleanup fails
    }
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final matchId = data['matchId'] as String?;

    // Suppress message notifications for the chat the user is currently viewing.
    if (type == 'message' && matchId != null) {
      final activeChatId = _ref.read(activeChatIdProvider);
      if (activeChatId == matchId) return;
    }

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: matchId,
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    final matchId = message.data['matchId'] as String?;
    _handleDeepLinkFromMatchId(matchId, data: message.data);
  }

  void _handleDeepLinkFromMatchId(String? matchId, {Map<String, dynamic>? data}) {
    if (matchId == null || matchId.isEmpty) return;
    final router = _ref.read(routerProvider);
    final name = data?['otherUserName'] ?? data?['senderName'] ?? 'Match';
    final photo = data?['otherUserPhoto'] ?? data?['senderPhoto'] ?? '';
    final userId = data?['otherUserId'] ?? data?['senderId'] ?? '';
    router.push(
      '/chat/$matchId'
      '?name=${Uri.encodeComponent(name)}'
      '&photo=${Uri.encodeComponent(photo)}'
      '&userId=${Uri.encodeComponent(userId)}',
    );
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

/// Holds the match ID of the chat the user is currently viewing, so the
/// foreground handler can suppress redundant notifications.
final activeChatIdProvider = StateProvider<String?>((ref) => null);
