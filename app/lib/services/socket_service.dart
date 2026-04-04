import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Real-time order tracking has been migrated to Supabase Realtime.
/// This stub preserves the interface so existing provider references compile.
class SocketService {
  final Ref ref;
  SocketService(this.ref);

  /// No-op: replaced by Supabase Realtime subscription in order_tracking_screen.
  void connect(String serverUrl, String orderId) {}

  void disconnect() {}
}

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService(ref);
});
