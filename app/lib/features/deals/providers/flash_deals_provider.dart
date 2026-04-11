import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final flashDealsFutureProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now().toIso8601String();

  try {
    final response = await supabase
        .from('flash_deals')
        .select('*, flash_deal_products(*, products(*))')
        .eq('is_active', true)
        .gte('end_time', now)
        .order('end_time', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    debugPrint('Supabase flash deals error: $e');
    return [];
  }
});
