import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/coupon.dart';

final couponsProvider = FutureProvider<List<Coupon>>((ref) async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now().toIso8601String();

  try {
    final response = await supabase
        .from('coupons')
        .select()
        .eq('is_active', true)
        .gte('valid_to', now)
        .order('value', ascending: false);

    return (response as List)
        .map((e) => Coupon.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    debugPrint('Supabase coupons error: \$e');
    // Fallback dummy data
    return [
      Coupon(
        id: '1',
        code: 'WELCOME50',
        discountType: 'flat',
        discountValue: 50.0,
        minOrderValue: 200.0,
        maxUses: 100,
        usedCount: 0,
        validUntil: DateTime.now().add(const Duration(days: 30)),
      ),
      Coupon(
        id: '2',
        code: 'FRESH20',
        discountType: 'percent',
        discountValue: 20.0,
        minOrderValue: 500.0,
        maxUses: 100,
        usedCount: 5,
        validUntil: DateTime.now().add(const Duration(days: 7)),
      ),
      Coupon(
        id: '3',
        code: 'TRYME100',
        discountType: 'flat',
        discountValue: 100.0,
        minOrderValue: 1000.0,
        maxUses: 50,
        usedCount: 49,
        validUntil: DateTime.now().add(const Duration(hours: 12)),
      ),
    ];
  }
});
