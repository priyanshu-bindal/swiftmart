import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/supabase_constants.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  GoRouter? _router;

  void setRouter(GoRouter router) {
    _router = router;
  }

  /// Keeps FCM token aligned when session changes (backup to AuthService flow).
  void listenToSupabaseAuthAndSaveToken() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      try {
        await _supabase
            .from(SupabaseConstants.profileTable)
            .update({
              'fcm_token': token,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', session.user.id);
        debugPrint('NotificationService: FCM token synced for user');
      } catch (e) {
        debugPrint('NotificationService: token sync failed: $e');
      }
    });
  }

  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint(
      'User granted notification permission: ${settings.authorizationStatus}',
    );

    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token Refreshed: $newToken');
      _saveTokenToSupabase(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Message Received: ${message.messageId}');
      debugPrint('Notification Payload: ${message.data}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification Clicked: ${message.messageId}');
      _handleNotificationClick(message);
    });

    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from(SupabaseConstants.profileTable)
          .update({
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      debugPrint('FCM token refreshed and saved');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('Notification Click Payload: ${message.data}');
    if (_router == null) return;

    final String? type = message.data['type'];
    if (type == 'flash_deal') {
      _router!.go('/flash-deals');
    } else if (type == 'CouponModel') {
      _router!.go('/coupons');
    }
  }
}
