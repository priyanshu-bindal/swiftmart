import 'dart:io';

void main() {
  final file = File('d:/Apps/swiftmart/app/lib/core/services/notification_service.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(RegExp(r"Future<void> _saveTokenToSupabase[\s\S]*?void _handleNotificationClick"), r"""
  Future<void> _saveTokenToSupabase(String token) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': 'android',
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint("? FCM token saved to Supabase");
    } catch (e) {
      debugPrint("? Error saving FCM token: ${e.toString()}");
    }
  }

  void _handleNotificationClick""");

  file.writeAsStringSync(content);
}
