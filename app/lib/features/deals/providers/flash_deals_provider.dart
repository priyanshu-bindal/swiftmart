import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/flash_deal.dart';
import '../../../models/product.dart';

final flashDealsProvider =
    AsyncNotifierProvider<FlashDealsNotifier, List<FlashDeal>>(() {
      return FlashDealsNotifier();
    });

class FlashDealsNotifier extends AsyncNotifier<List<FlashDeal>> {
  @override
  Future<List<FlashDeal>> build() async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now().toIso8601String();

    try {
      final response = await supabase
          .from('flash_deals')
          .select('*, products(*)')
          .eq('is_active', true)
          .gte('end_time', now)
          .order('end_time', ascending: true);

      return (response as List)
          .map((e) => FlashDeal.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Supabase error: ${e.toString()}');
      return [];
    }
  }
}
