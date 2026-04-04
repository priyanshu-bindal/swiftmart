import 'dart:io';

void main() {
  final file = File('d:/Apps/swiftmart/app/lib/features/auth/providers/auth_provider.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('package:firebase_auth/firebase_auth.dart')) {
    content = "import 'package:firebase_auth/firebase_auth.dart';\n" + content;
  }
  
  // Replace the inline logic to the exact one specified
  content = content.replaceAll(RegExp(r"final token = await FirebaseMessaging\.instance\.getToken\(\);\s*if \(token != null && user != null\) \{\s*await saveFcmToken\(token, user\.id\);\s*\}"), r"""
      final firebaseUser = FirebaseAuth.instance.currentUser;

      final token = await FirebaseMessaging.instance.getToken();

      debugPrint("TOKEN: $token");
      debugPrint("USER: ${firebaseUser?.uid}");

      if (token != null && firebaseUser != null) {
        await saveFcmToken(token, firebaseUser.uid);
      }
""");

  // For the the _fetchUserAndSetState
  content = content.replaceAll(RegExp(r"FirebaseMessaging\.instance\.getToken\(\)\.then\(\(token\) \{\s*if \(token != null && user != null\) \{\s*saveFcmToken\(token, user\.id\);\s*\}\s*\}\);"), r"""
        final firebaseUser = FirebaseAuth.instance.currentUser;
        final token = await FirebaseMessaging.instance.getToken();
        
        debugPrint("TOKEN: $token");
        debugPrint("USER: ${firebaseUser?.uid}");

        if (token != null && firebaseUser != null) {
          await saveFcmToken(token, firebaseUser.uid);
        }
""");

  // For the Auth listener part! Add it to the _init() where it makes sense or around _authSubscription
  if (!content.contains("FirebaseAuth.instance.authStateChanges().listen")) {
    content = content.replaceAll(RegExp(r"_authSubscription = _repository\.authStateChanges\(\)\.listen\(\(user\) \{"), r"""
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        final token = await FirebaseMessaging.instance.getToken();

        if (token != null) {
          await saveFcmToken(token, user.uid);
          debugPrint("? Token saved after login");
        }
      }
    });

    _authSubscription = _repository.authStateChanges().listen((user) {""");
  }

  file.writeAsStringSync(content);
}
