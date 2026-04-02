import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize();
  await Supabase.initialize(
    url: 'https://wfbxhuuvstahijtwsraf.supabase.co',
    anonKey: 'sb_publishable_0z4xzVT3isqJsF46-efEVw_QUwNAzx4',
  );
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 100; // 100MB
  PaintingBinding.instance.imageCache.maximumSize = 200; // max 200 images
  runApp(
    const ProviderScope(
      child: SwiftMartApp(),
    ),
  );
}

class SwiftMartApp extends HookConsumerWidget {
  const SwiftMartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
