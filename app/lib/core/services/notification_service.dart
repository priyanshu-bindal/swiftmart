import 'dart:convert';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();
  GoRouter? _router;

  // ── Notification channel ────────────────────────────────────────────────
  static const _orderChannel = AndroidNotificationChannel(
    'order_updates',
    'Order Updates',
    description: 'Notifications about your order status changes',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  void setRouter(GoRouter router) {
    _router = router;
  }

  // ── Initialize ──────────────────────────────────────────────────────────
  Future<void> initialize() async {
    // 1) Request permissions
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // 2) Create Android notification channel
    final androidPlugin =
        _localNotif.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_orderChannel);

    // 3) Init local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotif.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotifTap,
    );

    // 4) Get + save FCM token
    final token = await _fcm.getToken();
    if (token != null) await _saveTokenToSupabase(token);

    // 5) Listen for token refreshes
    _fcm.onTokenRefresh.listen(_saveTokenToSupabase);

    // 6) Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // 7) Background tap → route
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    // 8) App opened from terminated state via notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Slight delay so router is ready
      await Future.delayed(const Duration(milliseconds: 500));
      _handleNotificationClick(initialMessage);
    }
  }

  // ── Auth listener: save FCM token on login ──────────────────────────────
  void listenToSupabaseAuthAndSaveToken() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      if (data.session == null) return;
      final token = await _fcm.getToken();
      if (token != null) await _saveTokenToSupabase(token);
    });
  }

  // ── Save token to profiles table ────────────────────────────────────────
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
      debugPrint('FCM token saved for user $userId');
    } catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }

  // ── Show local notification (foreground) ────────────────────────────────
  void _showLocalNotification(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;

    _localNotif.show(
      id: message.hashCode,
      title: notif.title,
      body: notif.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _orderChannel.id,
          _orderChannel.name,
          channelDescription: _orderChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF0EA5E9),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Local notification tap handler ──────────────────────────────────────
  void _onLocalNotifTap(NotificationResponse response) {
    if (response.payload == null || _router == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _routeFromData(data);
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  // ── FCM notification tap handler ────────────────────────────────────────
  void _handleNotificationClick(RemoteMessage message) {
    _routeFromData(message.data);
  }

  // ── Route based on notification data ────────────────────────────────────
  void _routeFromData(Map<String, dynamic> data) {
    if (_router == null) return;

    final type = data['type']?.toString();
    final orderId = data['order_id']?.toString();

    if (type == 'order_status' && orderId != null && orderId.isNotEmpty) {
      _router!.push('/order-detail/$orderId');
    } else if (type == 'flash_deal') {
      _router!.push('/flash-deals');
    } else if (type == 'coupon') {
      _router!.push('/coupons');
    }
  }
}
