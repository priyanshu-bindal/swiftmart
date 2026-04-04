import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';

/// Foreground display + local notifications. Token persistence lives in [AuthService].
class FcmService {
  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  FcmService() {
    _initLocalNotifications();
  }

  void _initLocalNotifications() async {
    const androidConfig = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosConfig = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidConfig,
      iOS: iosConfig,
    );
    await _localNotifications.initialize(settings: initSettings);
  }

  Future<void> requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  void handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });
  }

  void handleBackgroundMessages() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Deep links can be handled here using GoRouter.
    });
  }

  /// Optional: sync token to `user_fcm_tokens` if you still use that table.
  /// Primary device token is stored on `users.fcm_token` by AuthService.
  void listenTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      try {
        await Supabase.instance.client.from(SupabaseConstants.profileTable).update({
          'fcm_token': newToken,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', uid);
      } catch (_) {}
    });
  }
}
