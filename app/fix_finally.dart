import 'dart:io';

void main() {
  final file = File('d:/Apps/swiftmart/app/lib/core/services/notification_service.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll("  void listenToAuthAndSaveToken() {\n    import 'package:firebase_auth/firebase_auth.dart'; // Will move this up with a script... Wait I can just use a bash script.\n}\n", "");
  content = content.replaceAll("  void listenToAuthAndSaveToken() {\r\n    import 'package:firebase_auth/firebase_auth.dart'; // Will move this up with a script... Wait I can just use a bash script.\r\n}\r\n", "");
  content = content.replaceAll(RegExp(r"\s*void listenToAuthAndSaveToken\(\) \{\r?\n\s*import 'package:firebase_auth/firebase_auth.dart';[^\}]*"), "");

  if (!content.contains("import 'package:firebase_auth/firebase_auth.dart';")) {
    content = "import 'package:firebase_auth/firebase_auth.dart';\n" + content;
  }
  
  if (!content.contains('void listenToAuthAndSaveToken()')) {
    content = content.replaceAll(RegExp(r"\s*\}\s*$", multiLine: true), r"""

  void listenToAuthAndSaveToken() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        debugPrint("?? User logged in: ${user.uid}");

        final token = await FirebaseMessaging.instance.getToken();

        debugPrint("?? TOKEN: $token");

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
}""");
  }

  file.writeAsStringSync(content);
}
