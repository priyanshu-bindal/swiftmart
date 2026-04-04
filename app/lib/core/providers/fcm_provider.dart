import 'package:riverpod/riverpod.dart';
import '../services/fcm_service.dart';

final fcmProvider = Provider<FcmService>((ref) {
  return FcmService();
});
