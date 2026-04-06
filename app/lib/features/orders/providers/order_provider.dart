import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:app/core/models/order_model.dart';

// ── Filter enum ───────────────────────────────────────────────────────────────

enum OrderFilter { all, active, delivered, cancelled }

final orderFilterProvider = StateProvider<OrderFilter>(
  (ref) => OrderFilter.all,
);

// ── Stream provider (realtime) ────────────────────────────────────────────────

final ordersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  final supabase = Supabase.instance.client;
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return Stream.value([]);

  // Initial fetch
  Future<List<OrderModel>> fetch() async {
    final response = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Stream that emits on every realtime change
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('user_id', uid)
      .asyncMap((_) => fetch()); // re-fetch with joined items on any change
});

// ── Filtered view ─────────────────────────────────────────────────────────────

final filteredOrdersProvider = Provider<AsyncValue<List<OrderModel>>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  final filter = ref.watch(orderFilterProvider);

  return ordersAsync.whenData((orders) {
    switch (filter) {
      case OrderFilter.all:
        return orders;
      case OrderFilter.active:
        return orders.where((o) => o.isActive).toList();
      case OrderFilter.delivered:
        return orders.where((o) => o.isDelivered).toList();
      case OrderFilter.cancelled:
        return orders.where((o) => o.isCancelled).toList();
    }
  });
});

// ── Legacy compat (used by old screens) ──────────────────────────────────────

final orderHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return [];
  try {
    final response = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('orderHistoryProvider error: $e\n$st');
    rethrow;
  }
});

// ── Single order by ID ────────────────────────────────────────────────────────

final orderByIdProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final supabase = Supabase.instance.client;
  try {
    final response = await supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .single();
    return OrderModel.fromJson(response);
  } catch (e) {
    debugPrint('orderByIdProvider error: $e');
    return null;
  }
});
