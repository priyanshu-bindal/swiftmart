import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:app/shared/widgets/app_network_image.dart';


import 'package:app/core/models/cart_item_model.dart';
import 'providers/cart_provider.dart';
import 'widgets/promo_code_bottom_sheet.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF0EA5E9);  // sky blue
const _kAccent  = Color(0xFFFF5722);  // flash-deal orange
const _kCombo   = Color(0xFF6C3CE1);  // combo purple
const _kBg      = Color(0xFFF5F6FA);
const _kCard    = Colors.white;
const _kText    = Color(0xFF111827);
const _kMuted   = Color(0xFF6B7280);

// ─────────────────────────────────────────────────────────────────────────────

class CartScreen extends HookConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync   = ref.watch(cartProvider);
    final subtotal    = ref.watch(cartSubtotalProvider);
    final deliveryFee = ref.watch(cartDeliveryFeeProvider);
    final discount    = ref.watch(cartDiscountProvider);
    final total       = ref.watch(cartTotalProvider);
    final appliedCode = ref.watch(appliedCouponCodeProvider);

    // Total savings for the header badge
    final savings = ref.watch(cartSavingsProvider);
    final totalSavings = savings.total + discount;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(context, totalSavings),
      body: cartAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kPrimary),
        ),
        error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(cartProvider)),
        data: (items) {
          if (items.isEmpty) return const _EmptyCartView();
          return _CartBody(
            items: items,
            subtotal: subtotal,
            deliveryFee: deliveryFee,
            discount: discount,
            total: total,
            appliedCode: appliedCode,
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext ctx, double totalSavings) {
    return AppBar(
      backgroundColor: _kCard,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _kBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: _kText),
        ),
        onPressed: () => ctx.pop(),
      ),
      title: const Text(
        'Your Cart',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w900,
          fontSize: 20,
          color: _kText,
        ),
      ),
      centerTitle: false,
      actions: [
        if (totalSavings > 0)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  'Saving ₹${totalSavings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, size: 48, color: _kAccent),
          const SizedBox(height: 16),
          const Text('Failed to load cart',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── Empty cart ───────────────────────────────────────────────────────────────

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    _kPrimary.withValues(alpha: 0.12),
                    _kPrimary.withValues(alpha: 0.04),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shoppingCart,
                  size: 58, color: _kPrimary),
            )
                .animate()
                .scale(
                    begin: const Offset(0.5, 0.5),
                    curve: Curves.elasticOut,
                    duration: 700.ms)
                .fadeIn(),
            const SizedBox(height: 28),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: _kText,
              ),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text(
              'Add products to get started.\nCombos & deals await you!',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kMuted, height: 1.6, fontSize: 14),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 36),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(LucideIcons.shoppingBag, size: 18),
              label: const Text('Shop Now',
                  style: TextStyle(
                      fontFamily: 'Manrope', fontWeight: FontWeight.w800)),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }
}

// ── Cart body ────────────────────────────────────────────────────────────────

class _CartBody extends HookConsumerWidget {
  final List<CartItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? appliedCode;

  const _CartBody({
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.appliedCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier       = ref.read(cartProvider.notifier);
    final showConfetti   = useState(false);
    final confettiKey    = useState(UniqueKey());

    // Group: combo items vs regular items
    final comboIds = <String>{};
    for (final item in items) {
      if (item.comboPartnerId != null) comboIds.add(item.productId);
    }

    final comboItems   = items.where((i) => comboIds.contains(i.productId)).toList();
    final regularItems = items.where((i) => !comboIds.contains(i.productId)).toList();

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [

                  // ── Regular items ──────────────────────────────────────
                  ...regularItems.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CartItemCard(item: e.value, notifier: notifier)
                          .animate(delay: (50 * e.key).ms)
                          .fadeIn(duration: 280.ms)
                          .slideX(begin: -0.03),
                    );
                  }),

                  // ── Combo group ────────────────────────────────────────
                  if (comboItems.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _ComboGroupCard(items: comboItems, notifier: notifier)
                        .animate(delay: 80.ms)
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.04),
                    const SizedBox(height: 4),
                  ],

                  const SizedBox(height: 12),

                  // ── Promo code row ─────────────────────────────────────
                  _PromoRow(
                    appliedCode: appliedCode,
                    onTap: () => _openPromoSheet(context, ref, showConfetti, confettiKey),
                    onRemove: () {
                      ref.read(cartDiscountProvider.notifier).state = 0;
                      ref.read(appliedCouponCodeProvider.notifier).state = null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // ── Bill summary ───────────────────────────────────────
                  _BillCard(
                    subtotal: subtotal,
                    deliveryFee: deliveryFee,
                    discount: discount,
                    total: total,
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),

            // ── Sticky bottom bar ────────────────────────────────────────
            _BottomBar(total: total),
          ],
        ),

        // ── Confetti ─────────────────────────────────────────────────────
        if (showConfetti.value)
          _CouponConfetti(
            key: confettiKey.value,
            onComplete: () => showConfetti.value = false,
          ),
      ],
    );
  }

  void _openPromoSheet(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> showConfetti,
    ValueNotifier<UniqueKey> confettiKey,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PromoCodeBottomSheet(subtotal: subtotal),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        ref.read(appliedCouponCodeProvider.notifier).state = result['code'] as String;
        ref.read(cartDiscountProvider.notifier).state = result['discount'] as double;
        HapticFeedback.mediumImpact();
        confettiKey.value = UniqueKey();
        showConfetti.value = true;
      }
    });
  }
}

// ── Combo group card ─────────────────────────────────────────────────────────

class _ComboGroupCard extends ConsumerWidget {
  final List<CartItemModel> items;
  final CartNotifier notifier;

  const _ComboGroupCard({required this.items, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectivePrices = ref.watch(cartEffectivePricesProvider);

    double regularTotal = 0;
    double comboTotal   = 0;
    for (final item in items) {
      final reg = item.product?.salePrice ?? 0;
      final eff = effectivePrices[item.productId] ?? reg;
      regularTotal += reg * item.quantity;
      comboTotal   += eff * item.quantity;
    }
    final savings = regularTotal - comboTotal;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F0FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kCombo.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kCombo.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🔥', style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Combo Offer Applied',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: _kCombo,
                    ),
                  ),
                ),
                if (savings > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kCombo,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Save ₹${savings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Items inside combo
          ...items.map((item) => Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                child: _CartItemCard(
                  item: item,
                  notifier: notifier,
                  isInCombo: true,
                ),
              )),

          // Bundle deal label
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kCombo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kCombo.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    '⭐ Bundle Deal',
                    style: TextStyle(
                      color: _kCombo,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _kPrimary.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Best Value',
                    style: TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single cart item card ─────────────────────────────────────────────────────

class _CartItemCard extends HookConsumerWidget {
  final CartItemModel item;
  final CartNotifier notifier;
  final bool isInCombo;

  const _CartItemCard({
    required this.item,
    required this.notifier,
    this.isInCombo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdating      = useState(false);
    final effectivePrices = ref.watch(cartEffectivePricesProvider);
    final pricing         = ref.watch(cartItemPricingProvider);
    final itemPricing     = pricing[item.productId];

    final effectiveUnit = effectivePrices[item.productId] ?? item.product?.salePrice ?? 0;
    final regular       = item.product?.salePrice ?? 0;
    final hasDiscount   = effectiveUnit < (regular - 0.01);

    // Determine badge type
    final bool isFlashDeal = hasDiscount && item.comboPartnerId == null;
    final bool isCombo     = item.comboPartnerId != null;

    Future<void> changeQty(int delta) async {
      if (isUpdating.value) return;
      isUpdating.value = true;
      HapticFeedback.selectionClick();
      try {
        await notifier.updateQuantity(item.id, item.quantity + delta);
      } finally {
        isUpdating.value = false;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isInCombo
            ? Colors.white.withValues(alpha: 0.8)
            : _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isInCombo
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Product image ───────────────────────────────────────────────
          Stack(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.product?.primaryImage?.isNotEmpty == true
                    ? AppNetworkImage(
                        imageUrl: item.product!.primaryImage!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                            LucideIcons.image,
                            color: _kMuted),
                      )
                    : const Icon(LucideIcons.shoppingBag,
                        color: _kMuted, size: 30),
              ),
              // Badge pill on image
              if (isFlashDeal || isCombo)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: isCombo ? _kCombo : _kAccent,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      isCombo ? 'Combo' : '⚡ Deal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // ── Product details ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Name + remove button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.product?.name ?? 'Unknown item',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _kText,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => notifier.removeFromCart(item.id),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x,
                            size: 12, color: _kMuted),
                      ),
                    ),
                  ],
                ),

                // Brand + unit
                if (item.product?.brand?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.product!.brand!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: _kMuted,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                if (item.product?.unit?.isNotEmpty == true)
                  Text(
                    item.product!.unit!,
                    style: const TextStyle(fontSize: 11, color: _kMuted),
                  ),

                const SizedBox(height: 10),

                // Price + stepper row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // Price column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount)
                            Text(
                              '₹${regular.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kMuted,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: _kMuted,
                              ),
                            ),
                          Text(
                            '₹${effectiveUnit.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: hasDiscount
                                  ? (isCombo ? _kCombo : _kAccent)
                                  : _kPrimary,
                            ),
                          ),
                          // Surplus qty hint (e.g. 2 at deal price + 1 at regular)
                          if ((itemPricing?.regularQty ?? 0) > 0 && (itemPricing?.dealQty ?? 0) > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '+${itemPricing!.regularQty} at ₹${itemPricing.regularUnitPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEAB308),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Quantity stepper
                    _QuantityStepper(
                      quantity: item.quantity,
                      isUpdating: isUpdating.value,
                      onDecrement: () => changeQty(-1),
                      onIncrement: () => changeQty(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quantity stepper ──────────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final bool isUpdating;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.isUpdating,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(
            icon: LucideIcons.minus,
            onTap: isUpdating ? null : onDecrement,
            color: _kText,
            bg: Colors.white,
          ),
          SizedBox(
            width: 32,
            child: Center(
              child: isUpdating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kPrimary))
                  : Text(
                      '$quantity',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _kText),
                    ),
            ),
          ),
          _StepBtn(
            icon: LucideIcons.plus,
            onTap: isUpdating ? null : onIncrement,
            color: Colors.white,
            bg: _kPrimary,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;

  const _StepBtn(
      {required this.icon, required this.color, required this.bg, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

// ── Promo code row ─────────────────────────────────────────────────────────────

class _PromoRow extends StatelessWidget {
  final String? appliedCode;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PromoRow({
    required this.appliedCode,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: appliedCode == null ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: appliedCode != null
              ? Border.all(color: _kPrimary.withValues(alpha: 0.4))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: appliedCode != null
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                appliedCode != null
                    ? LucideIcons.checkCircle2
                    : LucideIcons.tag,
                color: appliedCode != null ? _kPrimary : _kMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                appliedCode != null
                    ? '🎉  Coupon "$appliedCode" applied!'
                    : 'Apply Promo Code',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: appliedCode != null ? _kPrimary : _kText,
                ),
              ),
            ),
            if (appliedCode != null)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.x,
                      size: 14, color: Colors.redAccent),
                ),
              )
            else
              const Icon(LucideIcons.chevronRight,
                  color: _kMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Bill summary card ─────────────────────────────────────────────────────────

class _BillCard extends ConsumerWidget {
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;

  const _BillCard({
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savings = ref.watch(cartSavingsProvider);
    final flashSavings = savings.flash;
    final comboSavings = savings.combo;
    final totalSavings = savings.total + discount;

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.receipt, size: 16, color: _kMuted),
                SizedBox(width: 8),
                Text(
                  'Bill Summary',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _kText,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _BillRow('Item Total', '₹${subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 10),
                _BillRow(
                  'Delivery Fee',
                  subtotal > 499
                      ? 'FREE'
                      : '₹${deliveryFee.toStringAsFixed(2)}',
                  valueColor:
                      subtotal > 499 ? _kPrimary : null,
                ),

                // Flash savings
                if (flashSavings > 0) ...[
                  const SizedBox(height: 10),
                  _BillRow(
                    '⚡ Flash Deal Savings',
                    '-₹${flashSavings.toStringAsFixed(2)}',
                    valueColor: _kAccent,
                  ),
                ],

                // Combo savings
                if (comboSavings > 0) ...[
                  const SizedBox(height: 10),
                  _BillRow(
                    '🔥 Combo Savings',
                    '-₹${comboSavings.toStringAsFixed(2)}',
                    valueColor: _kCombo,
                  ),
                ],

                // Coupon discount
                if (discount > 0) ...[
                  const SizedBox(height: 10),
                  _BillRow(
                    '🎟  Coupon Discount',
                    '-₹${discount.toStringAsFixed(2)}',
                    valueColor: _kPrimary,
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9), thickness: 1.5),
                ),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount',
                        style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: _kText)),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: _kPrimary),
                    ),
                  ],
                ),

                // "You Saved" banner
                if (totalSavings > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFECFDF5),
                          _kPrimary.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: _kPrimary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          'You saved ₹${totalSavings.toStringAsFixed(0)} on this order!',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: _kPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BillRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: _kMuted, height: 1.4)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? _kText,
          ),
        ),
      ],
    );
  }
}

// ── Sticky bottom bar ─────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final double total;
  const _BottomBar({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: _kCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left: total label + amount
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL TO PAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: _kText,
                    ),
                  ),
                ],
              ),
            ),

            // Right: checkout CTA
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/checkout');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 26, vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coupon confetti overlay ───────────────────────────────────────────────────

class _CouponConfetti extends StatefulWidget {
  final VoidCallback onComplete;
  const _CouponConfetti({super.key, required this.onComplete});

  @override
  State<_CouponConfetti> createState() => _CouponConfettiState();
}

class _CouponConfettiState extends State<_CouponConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _colors = [
    Color(0xFF22C55E),
    Color(0xFFF97316),
    Color(0xFF6C3CE1),
    Color(0xFFFBBC04),
    Color(0xFFEC4899),
    Color(0xFF0EA5E9),
    Color(0xFF14B8A6),
    Color(0xFFEF4444),
  ];

  final _rng = Random();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward().whenComplete(widget.onComplete);

    _particles = List.generate(52, (i) {
      return _Particle(
        x: _rng.nextDouble(),
        size: 6 + _rng.nextDouble() * 9,
        color: _colors[i % _colors.length],
        delay: _rng.nextDouble() * 0.35,
        speed: 0.55 + _rng.nextDouble() * 0.45,
        isSquare: i % 3 != 0,
        sway: (_rng.nextDouble() - 0.5) * 0.15,
        rotation: _rng.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Stack(
            children: [
              ..._particles.map((p) {
                final progress =
                    ((t - p.delay) / p.speed).clamp(0.0, 1.0);
                if (progress <= 0) return const SizedBox.shrink();
                final opacity =
                    progress < 0.15 ? progress / 0.15 : (1 - progress);
                final top = -20.0 + (size.height + 40) * progress;
                final left = size.width * p.x +
                    sin(progress * pi * 3) * size.width * p.sway;
                return Positioned(
                  left: left,
                  top: top,
                  child: Transform.rotate(
                    angle: p.rotation + progress * pi * 4,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Container(
                        width: p.size,
                        height: p.isSquare ? p.size : p.size * 0.45,
                        decoration: BoxDecoration(
                          color: p.color,
                          borderRadius: p.isSquare
                              ? BorderRadius.circular(2)
                              : BorderRadius.circular(p.size),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (t > 0.05 && t < 0.85)
                Positioned(
                  top: size.height * 0.38,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: t < 0.15
                          ? (t - 0.05) / 0.1
                          : (t > 0.75 ? (0.85 - t) / 0.1 : 1.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Text(
                          '🎉  Coupon Applied!',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Particle {
  final double x, size, delay, speed, sway, rotation;
  final Color color;
  final bool isSquare;

  const _Particle({
    required this.x,
    required this.size,
    required this.color,
    required this.delay,
    required this.speed,
    required this.isSquare,
    required this.sway,
    required this.rotation,
  });
}
