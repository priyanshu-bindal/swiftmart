import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/models/coupon_model.dart';

final couponsProvider = FutureProvider<List<CouponModel>>((ref) async {
  final supabase = Supabase.instance.client;
  // Use UTC ISO string to avoid timezone mismatch with Supabase timestamptz
  final now = DateTime.now().toUtc().toIso8601String();

  try {
    final response = await supabase
        .from('coupons')
        .select()
        .eq('is_active', true)
        .gte('valid_to', now) // only filter expiry, not valid_from
        .order('discount_value', ascending: false);

    final list = List<Map<String, dynamic>>.from(response as List);
    debugPrint('Coupons fetched: ${list.length}');
    return list.map((e) => CouponModel.fromJson(e)).toList();
  } catch (e, st) {
    // Re-throw so the UI shows the actual error instead of silently returning []
    debugPrint('Supabase coupons error: $e\n$st');
    rethrow;
  }
});
