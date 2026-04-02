import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/supabase_provider.dart';
import '../models/cart_item.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return CartRepository(supabase: supabase);
});

class CartRepository {
  final SupabaseClient supabase;

  CartRepository({required this.supabase});

  String _getUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not authenticated");
    return user.uid;
  }

  Future<List<CartItem>> fetchCart() async {
    try {
      final uid = _getUid();
      final response = await supabase
          .from('cart_items')
          .select('*, products(*, categories(name))')
          .eq('user_id', uid);
          
      return (response as List<dynamic>).map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> syncItem(String productId, int quantity) async {
    try {
      final uid = _getUid();
      if (quantity > 0) {
        await supabase.from('cart_items').upsert({
          'user_id': uid,
          'product_id': productId,
          'quantity': quantity,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,product_id');
      } else {
        await supabase
            .from('cart_items')
            .delete()
            .eq('user_id', uid)
            .eq('product_id', productId);
      }
    } catch (_) {}
  }

  Future<void> clearCart() async {
    try {
      final uid = _getUid();
      await supabase.from('cart_items').delete().eq('user_id', uid);
    } catch (_) {}
  }
}
