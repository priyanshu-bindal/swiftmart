import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/models/cart_item_model.dart';

// ── CouponModel discount state ────────────────────────────────────────────────────
/// Holds the flat discount amount (in ₹) from an applied coupon.
final cartDiscountProvider = StateProvider<double>((ref) => 0.0);

/// Holds the applied CouponModel code string (null = no CouponModel).
final appliedCouponCodeProvider = StateProvider<String?>((ref) => null);

// ── Cart state ───────────────────────────────────────────────────────────────

class CartNotifier extends AsyncNotifier<List<CartItemModel>> {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Firebase UID - stored as TEXT in cart_items.user_id.
  /// (The cart_items.user_id column must be TEXT type, not UUID.)
  String? get _uid => _supabase.auth.currentUser?.id;

  @override
  Future<List<CartItemModel>> build() async {
    final uid = _uid;
    if (uid == null) return [];
    return _fetchCart(uid);
  }

  Future<List<CartItemModel>> _fetchCart(String uid) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select('*, products(*)')
          .eq('user_id', uid);
      return (response as List)
          .map((json) => CartItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Re-throw with a clearer message so the cart error state shows it.
      throw Exception('Cart fetch failed: $e');
    }
  }

  /// Add or increment item in cart (upserts on user_id+product_id conflict).
  Future<void> addToCart(String productId, {int quantity = 1}) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('Please login to add items to the cart');
    }

    final current = state.asData?.value ?? [];
    final existing = current.where((i) => i.productId == productId).firstOrNull;
    final newQty = (existing?.quantity ?? 0) + quantity;

    await _supabase.from('cart_items').upsert({
      'user_id': uid,
      'product_id': productId,
      'quantity': newQty,
    }, onConflict: 'user_id,product_id');
    state = AsyncData(await _fetchCart(uid));
  }

  /// Update quantity of a specific cart row. quantity == 0 removes it.
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    final uid = _uid;
    if (uid == null) return;

    if (quantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }
    await _supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);
    state = AsyncData(await _fetchCart(uid));
  }

  /// Remove a single cart row by its DB id.
  Future<void> removeFromCart(String cartItemId) async {
    final uid = _uid;
    if (uid == null) return;
    await _supabase.from('cart_items').delete().eq('id', cartItemId);
    state = AsyncData(await _fetchCart(uid));
  }

  /// Delete all cart rows for the current user.
  Future<void> clearCart() async {
    final uid = _uid;
    if (uid == null) return;
    await _supabase.from('cart_items').delete().eq('user_id', uid);
    state = const AsyncData([]);
  }

  /// Convenience: get current items list synchronously.
  List<CartItemModel> get currentItems => state.asData?.value ?? [];

  /// Decrement or remove via cart item id + current quantity.
  Future<void> decrementItem(CartItemModel item) =>
      updateQuantity(item.id, item.quantity - 1);
}

final cartProvider = AsyncNotifierProvider<CartNotifier, List<CartItemModel>>(
  CartNotifier.new,
);

// ── Computed selectors (read-only providers) ─────────────────────────────────

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider).asData?.value ?? [];
  return items.fold(0, (sum, i) => sum + i.quantity);
});

final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider).asData?.value ?? [];
  return items.fold(0.0, (sum, i) => sum + i.totalPrice);
});

final cartDeliveryFeeProvider = Provider<double>((ref) {
  return 40.0; // Flat ₹40 delivery fee
});

final cartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final discount = ref.watch(cartDiscountProvider);
  final delivery = ref.watch(cartDeliveryFeeProvider);
  final total = subtotal - discount + delivery;
  return total < 0 ? 0 : total;
});
