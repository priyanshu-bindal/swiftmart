import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app/routes/app_router.dart';
import 'core/services/remote_config_service.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/supabase_constants.dart';
import 'firebase_options.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    final rcs = RemoteConfigService(remoteConfig);
    await rcs.init();
  } catch (e) {
    debugPrint('Failed to initialize Remote Config: $e');
  }

  PaintingBinding.instance.imageCache.maximumSizeBytes =
      1024 * 1024 * 100; // 100MB
  PaintingBinding.instance.imageCache.maximumSize = 200; // max 200 images

  runApp(const ProviderScope(child: SwiftMartApp()));
}

class SwiftMartApp extends ConsumerStatefulWidget {
  const SwiftMartApp({super.key});

  @override
  ConsumerState<SwiftMartApp> createState() => _SwiftMartAppState();
}

class _SwiftMartAppState extends ConsumerState<SwiftMartApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      final notifService = ref.read(notificationServiceProvider);
      notifService.setRouter(router);
      notifService.initialize();
    });

    NotificationService().listenToSupabaseAuthAndSaveToken();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C3CE1),
          primary: const Color(0xFF6C3CE1),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      routerConfig: router,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}
