import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../core/models/order_model.dart';

/// Streams the most recent active order (CONFIRMED, OUT_FOR_DELIVERY)
/// for the current user. Returns null when no active order exists.
final activeOrderProvider = StreamProvider<OrderModel?>((ref) {
  final supabase = Supabase.instance.client;
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return Stream.value(null);

  // Full fetch including order_items
  Future<OrderModel?> fetchLatestActive() async {
    try {
      final response = await supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', uid)
          .inFilter('status', ['CONFIRMED', 'OUT_FOR_DELIVERY', 'confirmed', 'out_for_delivery'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('activeOrderProvider fetch error: $e');
      return null;
    }
  }

  // Listen for realtime changes on the orders table and re-fetch
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('user_id', uid)
      .asyncMap((_) => fetchLatestActive());
});
