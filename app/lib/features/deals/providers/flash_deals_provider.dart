import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/flash_deal.dart';
import '../../../models/product.dart';

final flashDealsProvider = AsyncNotifierProvider<FlashDealsNotifier, List<FlashDeal>>(() {
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

      return (response as List).map((e) => FlashDeal.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Supabase flash deals error: \$e');
      // Fallback
      return [
        FlashDeal(
          id: '1',
          product: const Product(
            id: 'mock-1',
            name: 'Organic Apples',
            price: 5.99,
            imagePath: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6faa6',
            unit: '1 kg',
            stockCount: 100,
          ),
          discountPercent: 30,
          endTime: DateTime.now().add(const Duration(hours: 4)),
          maxQty: 100,
          soldQty: 45,
        ),
        FlashDeal(
          id: '2',
          product: const Product(
            id: 'mock-2',
            name: 'Fresh Dairy Milk',
            price: 2.49,
            imagePath: 'https://images.unsplash.com/photo-1563636619-e9143da7973b',
            unit: '1 L',
            stockCount: 50,
          ),
          discountPercent: 15,
          endTime: DateTime.now().add(const Duration(hours: 1)),
          maxQty: 50,
          soldQty: 10,
        )
      ];
    }
  }
}
