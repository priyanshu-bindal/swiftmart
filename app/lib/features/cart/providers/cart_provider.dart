import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app/core/models/cart_item_model.dart';
import 'package:app/core/models/product_model.dart';
import '../../deals/providers/flash_deal_price_provider.dart';
import '../../deals/providers/flash_deals_provider.dart';

// ── Coupon discount state ─────────────────────────────────────────────────────
final cartDiscountProvider = StateProvider<double>((ref) => 0.0);
final appliedCouponCodeProvider = StateProvider<String?>((ref) => null);

// ── Cart state ────────────────────────────────────────────────────────────────

class CartNotifier extends AsyncNotifier<List<CartItemModel>> {
  SupabaseClient get _supabase => Supabase.instance.client;
  String? get _uid => _supabase.auth.currentUser?.id;

  final Map<String, String> _comboLinks = {};

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
      final items = (response as List)
          .map((json) => CartItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return _applyComboLinks(items);
    } catch (e) {
      throw Exception('Cart fetch failed: $e');
    }
  }

  List<CartItemModel> _applyComboLinks(List<CartItemModel> items) {
    return items.map((item) {
      final partnerId = _comboLinks[item.productId];
      if (partnerId != null && items.any((i) => i.productId == partnerId)) {
        return item.copyWith(comboPartnerId: partnerId);
      }
      return item.copyWith(clearCombo: true);
    }).toList();
  }

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Please login to add items to the cart');
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

  Future<void> addComboToCart({
    required ProductModel productA,
    required ProductModel productB,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Please login to add items to the cart');
    final current = state.asData?.value ?? [];
    final existingA = current.where((i) => i.productId == productA.id).firstOrNull;
    final existingB = current.where((i) => i.productId == productB.id).firstOrNull;
    final newQtyA = (existingA?.quantity ?? 0) + 1;
    final newQtyB = (existingB?.quantity ?? 0) + 1;
    await _supabase.from('cart_items').upsert([
      {'user_id': uid, 'product_id': productA.id, 'quantity': newQtyA},
      {'user_id': uid, 'product_id': productB.id, 'quantity': newQtyB},
    ], onConflict: 'user_id,product_id');
    _comboLinks[productA.id] = productB.id;
    _comboLinks[productB.id] = productA.id;
    state = AsyncData(await _fetchCart(uid));
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    final uid = _uid;
    if (uid == null) return;
    if (quantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }
    await _supabase
        .from('cart_items')
        .update({'quantity': quantity}).eq('id', cartItemId);
    state = AsyncData(await _fetchCart(uid));
  }

  Future<void> removeFromCart(String cartItemId) async {
    final uid = _uid;
    if (uid == null) return;
    final items = state.asData?.value ?? [];
    final removed = items.where((i) => i.id == cartItemId).firstOrNull;
    if (removed != null) {
      final partnerId = _comboLinks[removed.productId];
      _comboLinks.remove(removed.productId);
      if (partnerId != null) _comboLinks.remove(partnerId);
      ref.read(flashDealPriceProvider.notifier).clearOverride(removed.productId);
    }
    await _supabase.from('cart_items').delete().eq('id', cartItemId);
    state = AsyncData(await _fetchCart(uid));
  }

  Future<void> clearCart() async {
    final uid = _uid;
    if (uid == null) return;
    _comboLinks.clear();
    ref.read(flashDealPriceProvider.notifier).clearAll();
    await _supabase.from('cart_items').delete().eq('user_id', uid);
    state = const AsyncData([]);
  }

  List<CartItemModel> get currentItems => state.asData?.value ?? [];

  Future<void> decrementItem(CartItemModel item) =>
      updateQuantity(item.id, item.quantity - 1);
}

final cartProvider = AsyncNotifierProvider<CartNotifier, List<CartItemModel>>(
  CartNotifier.new,
);

// ── Computed selectors ────────────────────────────────────────────────────────

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider).asData?.value ?? [];
  return items.fold(0, (sum, i) => sum + i.quantity);
});

// ── NEW: Quantity-aware per-item line total result ────────────────────────────

/// Holds the fully computed pricing for one cart item.
/// dealQty = units that got the deal/combo price
/// regularQty = surplus units at base salePrice
class CartItemPricing {
  final double dealUnitPrice;    // price per unit for deal/combo qty
  final double regularUnitPrice; // base salePrice for surplus qty
  final int dealQty;             // how many units got the deal
  final int regularQty;          // surplus units at regular price
  final double lineTotal;        // total cost for this cart row
  final double lineSavings;      // how much saved vs all-regular

  const CartItemPricing({
    required this.dealUnitPrice,
    required this.regularUnitPrice,
    required this.dealQty,
    required this.regularQty,
    required this.lineTotal,
    required this.lineSavings,
  });

  /// Effective display unit price (used for the price label in the card).
  /// Shows deal price if any deal qty exists, else regular.
  double get displayUnitPrice => dealQty > 0 ? dealUnitPrice : regularUnitPrice;

  bool get hasDiscount => dealQty > 0 && dealUnitPrice < (regularUnitPrice - 0.01);
}

/// Maps productId -> CartItemPricing with full quantity-aware breakdown.
///
/// Flash deal: only 1 unit gets the deal price per product (qty 1 cap).
/// Combo deal: min(qtyA, qtyB) sets get combo price, surplus at regular.
/// Priority: manualOverride > flashDeal (qty-capped at 1) > combo > regular
final cartItemPricingProvider = Provider<Map<String, CartItemPricing>>((ref) {
  final items = ref.watch(cartProvider).asData?.value ?? [];
  final manualOverrides = ref.watch(flashDealPriceProvider);

  // Build deal lookup maps
  final Map<String, double?> dealOverridePrices = {};
  final Map<String, double> dealDiscountPcts = {};

  ref.watch(flashDealsFutureProvider).whenData((deals) {
    for (final deal in deals) {
      final pct = (deal['discount_percent'] as num?)?.toDouble() ?? 0;
      final products = deal['flash_deal_products'] as List? ?? [];
      for (final p in products) {
        final productId = p['product_id']?.toString();
        if (productId == null) continue;
        dealOverridePrices[productId] = (p['override_price'] as num?)?.toDouble();
        dealDiscountPcts[productId] = pct;
      }
    }
  });

  // Build a quick quantity lookup


  final Map<String, CartItemPricing> result = {};

  // Track which combo pairs we've already processed (to avoid double-counting)
  final processedCombos = <String>{};

  for (final item in items) {
    final regular = item.product?.salePrice ?? 0.0;
    final qty = item.quantity;

    // ── Case 1: Manual session override (always 1 unit deal, rest regular) ──
    if (manualOverrides.containsKey(item.productId)) {
      final dealPrice = manualOverrides[item.productId]!;
      // Cap: only 1 unit gets the manual override deal
      final dealQty = qty.clamp(0, 1);
      final regularQty = qty - dealQty;
      final lineTotal = dealQty * dealPrice + regularQty * regular;
      final lineSavings = dealQty * (regular - dealPrice);
      result[item.productId] = CartItemPricing(
        dealUnitPrice: dealPrice,
        regularUnitPrice: regular,
        dealQty: dealQty,
        regularQty: regularQty,
        lineTotal: lineTotal,
        lineSavings: lineSavings,
      );
      continue;
    }

    // ── Case 2: Flash deal from DB (cap at 1 unit per product) ───────────────
    if (dealOverridePrices.containsKey(item.productId) ||
        (dealDiscountPcts[item.productId] ?? 0) > 0) {
      double dealPrice;
      if (dealOverridePrices.containsKey(item.productId) &&
          dealOverridePrices[item.productId] != null) {
        dealPrice = dealOverridePrices[item.productId]!;
      } else {
        final pct = dealDiscountPcts[item.productId]!;
        dealPrice = regular * (1 - pct / 100);
      }

      // KEY FIX: Flash deals cap at 1 unit. Surplus units pay regular price.
      final dealQty = qty.clamp(0, 1);
      final regularQty = qty - dealQty;
      final lineTotal = dealQty * dealPrice + regularQty * regular;
      final lineSavings = dealQty * (regular - dealPrice);

      result[item.productId] = CartItemPricing(
        dealUnitPrice: dealPrice,
        regularUnitPrice: regular,
        dealQty: dealQty,
        regularQty: regularQty,
        lineTotal: lineTotal,
        lineSavings: lineSavings,
      );
      continue;
    }

    // ── Case 3: Combo deal — process the pair together ────────────────────────
    if (item.comboPartnerId != null) {
      final partnerId = item.comboPartnerId!;
      final comboKey = ([item.productId, partnerId]..sort()).join('|');

      // Skip if this pair was already handled when we processed the partner
      if (processedCombos.contains(comboKey)) continue;
      processedCombos.add(comboKey);

      final partnerItem = items.where((i) => i.productId == partnerId).firstOrNull;
      if (partnerItem == null) {
        // Partner gone — treat as regular
        result[item.productId] = CartItemPricing(
          dealUnitPrice: regular,
          regularUnitPrice: regular,
          dealQty: 0,
          regularQty: qty,
          lineTotal: qty * regular,
          lineSavings: 0,
        );
        continue;
      }

      final partnerRegular = partnerItem.product?.salePrice ?? 0.0;
      final partnerQty = partnerItem.quantity;

      // Number of complete combo sets = min of both quantities
      final comboSets = qty < partnerQty ? qty : partnerQty;
      final surplusA = qty - comboSets;
      final surplusB = partnerQty - comboSets;

      final comboPriceA = item.product?.comboDeal?.thisItemComboPrice ?? regular;
      final comboPriceB = partnerItem.product?.comboDeal?.thisItemComboPrice ?? partnerRegular;

      // Item A pricing
      final lineTotalA = comboSets * comboPriceA + surplusA * regular;
      final lineSavingsA = comboSets * (regular - comboPriceA);
      result[item.productId] = CartItemPricing(
        dealUnitPrice: comboPriceA,
        regularUnitPrice: regular,
        dealQty: comboSets,
        regularQty: surplusA,
        lineTotal: lineTotalA,
        lineSavings: lineSavingsA,
      );

      // Item B pricing
      final lineTotalB = comboSets * comboPriceB + surplusB * partnerRegular;
      final lineSavingsB = comboSets * (partnerRegular - comboPriceB);
      result[partnerId] = CartItemPricing(
        dealUnitPrice: comboPriceB,
        regularUnitPrice: partnerRegular,
        dealQty: comboSets,
        regularQty: surplusB,
        lineTotal: lineTotalB,
        lineSavings: lineSavingsB,
      );
      continue;
    }

    // ── Case 4: Regular price ─────────────────────────────────────────────────
    result[item.productId] = CartItemPricing(
      dealUnitPrice: regular,
      regularUnitPrice: regular,
      dealQty: 0,
      regularQty: qty,
      lineTotal: qty * regular,
      lineSavings: 0,
    );
  }

  return result;
});

/// Flat effective price map — kept for backward compat with any widget
/// that still reads cartEffectivePricesProvider.
/// Uses displayUnitPrice (deal price if any deal qty, else regular).
final cartEffectivePricesProvider = Provider<Map<String, double>>((ref) {
  final pricing = ref.watch(cartItemPricingProvider);
  return pricing.map((id, p) => MapEntry(id, p.displayUnitPrice));
});

/// Subtotal = sum of all lineTotals (quantity-aware, correct).
final cartSubtotalProvider = Provider<double>((ref) {
  final pricing = ref.watch(cartItemPricingProvider);
  return pricing.values.fold(0.0, (sum, p) => sum + p.lineTotal);
});

/// Total savings split by type.
final cartSavingsProvider = Provider<({double flash, double combo, double total})>((ref) {
  final items = ref.watch(cartProvider).asData?.value ?? [];
  final pricing = ref.watch(cartItemPricingProvider);

  double flash = 0;
  double combo = 0;
  for (final item in items) {
    final p = pricing[item.productId];
    if (p == null || p.lineSavings <= 0) continue;
    if (item.comboPartnerId != null) {
      combo += p.lineSavings;
    } else {
      flash += p.lineSavings;
    }
  }
  return (flash: flash, combo: combo, total: flash + combo);
});

/// Legacy — combo savings only.
final comboSavingsProvider = Provider<double>((ref) {
  return ref.watch(cartSavingsProvider).combo;
});

final cartDeliveryFeeProvider = Provider<double>((ref) => 40.0);

/// Free delivery progress tracker.
final cartFreeDeliveryProvider =
    Provider<({double threshold, double remaining, double progress, bool isFree})>((ref) {
  const threshold = 499.0;
  final subtotal = ref.watch(cartSubtotalProvider);
  final remaining = (threshold - subtotal).clamp(0.0, double.infinity);
  final progress = (subtotal / threshold).clamp(0.0, 1.0);
  final isFree = subtotal >= threshold;
  return (threshold: threshold, remaining: remaining, progress: progress, isFree: isFree);
});

final cartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final discount = ref.watch(cartDiscountProvider);
  final delivery = ref.watch(cartDeliveryFeeProvider);
  final freeDelivery = ref.watch(cartFreeDeliveryProvider);
  final effectiveDelivery = freeDelivery.isFree ? 0.0 : delivery;
  final total = subtotal - discount + effectiveDelivery;
  return total < 0 ? 0 : total;
});

final cartSuggestedProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  try {
    final cartItems = ref.watch(cartProvider).asData?.value ?? [];
    final cartProductIds = cartItems.map((item) => item.productId).toList();
    
    var query = Supabase.instance.client.from('products')
        .select('*, categories(name)')
        .eq('is_active', true);
        
    if (cartProductIds.isNotEmpty) {
      query = query.not('id', 'in', cartProductIds);
    }
    
    final response = await query.order('sale_price', ascending: false).limit(6);
    
    return (response as List).map((data) => ProductModel.fromJson(data)).toList();
  } catch (e) {
    print('Error in cartSuggestedProductsProvider: $e');
    return [];
  }
});