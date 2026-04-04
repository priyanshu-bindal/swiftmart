import 'dart:io';

void main() {
  final file = File('d:/Apps/swiftmart/app/lib/core/services/notification_service.dart');
  file.writeAsStringSync("""
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

  void listenToAuthAndSaveToken() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        debugPrint("?? User logged in: \${user.uid}");

        final token = await FirebaseMessaging.instance.getToken();

        debugPrint("?? TOKEN: \$token");

        if (token != null) {
          await Supabase.instance.client.from('user_fcm_tokens').upsert({
            'user_id': user.uid,
            'token': token,
            'platform': 'android',
            'updated_at': DateTime.now().toIso8601String(),
          });

          debugPrint("? Token saved to Supabase");
        }
      }
    });
  }

  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted notification permission: \${settings.authorizationStatus}');

    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token Refreshed: \$newToken');
      _saveTokenToSupabase(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Message Received: \${message.messageId}');
      debugPrint('Notification Payload: \${message.data}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification Clicked: \${message.messageId}');
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
      await _supabase.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': 'android',
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint("? FCM token refreshed and saved to Supabase");
    } catch (e) {
      debugPrint("? Error saving FCM token: \${e.toString()}");
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('Notification Click Payload: \${message.data}');
    if (_router == null) return;

    final String? type = message.data['type'];
    if (type == 'flash_deal') {
      _router!.go('/flash-deals');
    } else if (type == 'coupon') {
      _router!.go('/coupons');
    }
  }
}
""");
}
