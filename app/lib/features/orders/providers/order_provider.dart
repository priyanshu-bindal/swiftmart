import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/models/order_model.dart';

final orderHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  final response = await supabase
      .from('orders')
      .select('*, items:order_items(*)')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  return (response as List)
      .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
