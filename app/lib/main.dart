import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'app/routes/app_router.dart';
import 'core/services/remote_config_service.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/supabase_constants.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase init
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Supabase init
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );

  // Initialize Remote Config
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    final rcs = RemoteConfigService(remoteConfig);
    await rcs.init();
  } catch (e) {
    debugPrint('Failed to initialize Remote Config: \$e');
  }
  
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 100; // 100MB
  PaintingBinding.instance.imageCache.maximumSize = 200; // max 200 images
  
  runApp(const ProviderScope(child: SwiftMartApp()));
}

class SwiftMartApp extends ConsumerWidget {
  const SwiftMartApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

