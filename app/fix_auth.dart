import 'dart:io';

void main() {
  final file = File('d:/Apps/swiftmart/app/lib/features/auth/providers/auth_provider.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('package:firebase_messaging/firebase_messaging.dart')) {
    content = "import 'package:flutter/foundation.dart';\nimport 'package:firebase_messaging/firebase_messaging.dart';\nimport 'package:supabase_flutter/supabase_flutter.dart';\n" + content;
  }
  
  if (!content.contains('saveFcmToken')) {
    content = content + """
Future<void> saveFcmToken(String token, String userId) async {
  final supabase = Supabase.instance.client;

  try {
    await supabase.from('user_fcm_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': 'android',
      'updated_at': DateTime.now().toIso8601String(),
    });

    debugPrint("? FCM token saved to Supabase");
  } catch (e) {
    debugPrint("? Error saving FCM token: \${e.toString()}");
  }
}
""";
  }

  // Replace fcmService.saveTokenToSupabase with the explicit logic
  content = content.replaceAll(RegExp(r"await fcmService\.saveTokenToSupabase\(\);\s*"), r"""
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && user != null) {
        await saveFcmToken(token, user.id);
      }
      
""");

  // Also replace without await for _fetchUserAndSetState
  content = content.replaceAll(RegExp(r"fcmService\.saveTokenToSupabase\(\);\s*"), r"""
        FirebaseMessaging.instance.getToken().then((token) {
          if (token != null && user != null) {
            saveFcmToken(token, user.id);
          }
        });
        
""");

  file.writeAsStringSync(content);
}
