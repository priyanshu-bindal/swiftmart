import 'dart:io';
void main() {
  final fp = File('d:/Apps/swiftmart/app/lib/core/services/notification_service.dart');
  var x = fp.readAsStringSync();
  // Clear any extra declarations I might have created that shadows FirebaseMessaging accidentally.
  x = x.replaceAll(RegExp(r"^[\s]*FirebaseMessaging\(\) \{.*\}", multiLine: true), "");
  x = x.replaceAll("import 'package:firebase_auth/firebase_auth.dart';", 
  """import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';""");
  fp.writeAsStringSync(x);
}
