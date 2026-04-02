import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `await Firebase.initializeApp()` before using other Firebase services.
  debugPrint('Handling a background message: ${message.messageId}');
}

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  OverlayEntry? _overlayEntry;

  Future<void> init(BuildContext context) async {
    // Request permission for iOS and Android
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Set the background messaging handler early on, as a top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle messages while app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null && context.mounted) {
        _showInAppBanner(
            context, message.notification!.title, message.notification!.body);
      }
    });

    // Handle notifications tapped while app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // Navigate to order history or specific order screen typically here
    });
  }

  void _showInAppBanner(BuildContext context, String? title, String? body) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _FancyNotificationBanner(title: title, body: body);
      },
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Automatically remove after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (_overlayEntry != null) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
    });
  }
}

class _FancyNotificationBanner extends StatefulWidget {
  final String? title;
  final String? body;

  const _FancyNotificationBanner({super.key, this.title, this.body});

  @override
  __FancyNotificationBannerState createState() => __FancyNotificationBannerState();
}

class __FancyNotificationBannerState extends State<_FancyNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600)); // Slow

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut, // Elastic Out for bouncy elements
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    Widget banner = Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF6C3CE1), // Primary Deep Violet
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications_active, color: Color(0xFF00D4AA), size: 28), // Teal Mint
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ?? 'Status Update',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.body ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (disableAnimations) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: banner,
        ),
      );
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _slideAnimation,
          child: banner,
        ),
      ),
    );
  }
}