import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app/shared/widgets/app_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cart_item.dart';
import 'providers/cart_provider.dart';

class CartScreen extends HookConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryFee = ref.watch(cartDeliveryFeeProvider);
    final discount = ref.watch(cartDiscountProvider);
    final total = ref.watch(cartTotalProvider);
    final appliedCode = ref.watch(appliedCouponCodeProvider);
    final isValidatingCoupon = useState(false);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: AppBar(
              backgroundColor: AppColors.primaryFixedDim.withValues(alpha: 0.7),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.primary,
                ),
                onPressed: () => context.pop(),
              ),
              title: const Text(
                'Your Basket',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.primary,
                ),
              ),
              actions: [
                cartAsync.maybeWhen(
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : TextButton(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Clear cart?'),
                                content: const Text(
                                  'Remove all items from your basket?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => ctx.pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => ctx.pop(true),
                                    child: const Text(
                                      'Clear',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await ref.read(cartProvider.notifier).clearCart();
                            }
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: cartAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.alertCircle,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load cart',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => ref.invalidate(cartProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyCartView();
          }
          return _CartListView(
            items: items,
            subtotal: subtotal,
            deliveryFee: deliveryFee,
            discount: discount,
            total: total,
            appliedCode: appliedCode,
            isValidatingCoupon: isValidatingCoupon,
          );
        },
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyCartView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.shoppingCart,
                    size: 56,
                    color: AppColors.primary,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  curve: Curves.elasticOut,
                  duration: 700.ms,
                )
                .fadeIn(),
            const SizedBox(height: 32),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: AppColors.onSurface,
              ),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text(
              'Browse our products and add\nsomething delicious!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.5),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(LucideIcons.shoppingBag, size: 18),
              label: const Text(
                'Shop Now',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }
}

// ── Scrollable cart list + sticky bottom bar ─────────────────────────────────

class _CartListView extends HookConsumerWidget {
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final String? appliedCode;
  final ValueNotifier<bool> isValidatingCoupon;

  const _CartListView({
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.appliedCode,
    required this.isValidatingCoupon,
  });

  Future<void> _handleCouponNavigation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await context.push<String>(
      '/coupons',
      extra: {'fromCart': true},
    );
    if (result == null || !context.mounted) return;

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    isValidatingCoupon.value = true;
    try {
      // Direct client-side validation logic since Edge Function is not deployed
      final response = await Supabase.instance.client
          .from('coupons')
          .select('*')
          .eq('code', result)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        throw Exception('Invalid or expired coupon');
      }

      final now = DateTime.now();
      final validFrom = response['valid_from'] != null
          ? DateTime.parse(response['valid_from'])
          : null;
      final validTo = response['valid_to'] != null
          ? DateTime.parse(response['valid_to'])
          : null;
      final maxUses = response['max_uses'] as int? ?? 100;
      final usedCount = response['used_count'] as int? ?? 0;
      final minOrder = (response['min_order'] as num?)?.toDouble() ?? 0.0;
      final type = response['type'] as String? ?? 'flat';
      final value = (response['value'] as num?)?.toDouble() ?? 0.0;

      if (validFrom != null && now.isBefore(validFrom))
        throw Exception('Coupon not yet active');
      if (validTo != null && now.isAfter(validTo))
        throw Exception('Coupon expired');
      if (usedCount >= maxUses) throw Exception('Coupon limit reached');
      if (subtotal < minOrder)
        throw Exception('Minimum order value should be ₹$minOrder');

      double discountVal = 0.0;
      if (type == 'flat' || type == 'cashback') {
        discountVal = value;
      } else if (type == 'percent') {
        discountVal = (subtotal * value) / 100;
      } else if (type == 'free_delivery') {
        discountVal = value;
      }

      ref.read(cartDiscountProvider.notifier).state = discountVal;
      ref.read(appliedCouponCodeProvider.notifier).state = result;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              discountVal > 0
                  ? 'Coupon applied! You save ₹${discountVal.toStringAsFixed(0)}'
                  : 'Coupon applied!',
            ),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not apply coupon: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      isValidatingCoupon.value = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(
            top: 100,
            left: 20,
            right: 20,
            bottom: 260,
          ),
          children: [
            // ── Cart items ───────────────────────────────────────────────
            ...items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child:
                    Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => notifier.removeFromCart(item.id),
                          background: Container(
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Icon(
                              LucideIcons.trash2,
                              color: AppColors.onError,
                            ),
                          ),
                          child: _CartItemRow(item: item, notifier: notifier),
                        )
                        .animate(delay: (60 * idx).ms)
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: -0.05),
              );
            }),

            const SizedBox(height: 8),

            // ── Coupon row ───────────────────────────────────────────────
            InkWell(
              onTap: isValidatingCoupon.value
                  ? null
                  : () => _handleCouponNavigation(context, ref),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: appliedCode != null
                      ? AppColors.secondary.withValues(alpha: 0.08)
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: appliedCode != null
                      ? Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: appliedCode != null
                            ? AppColors.secondary.withValues(alpha: 0.15)
                            : AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        appliedCode != null
                            ? LucideIcons.checkCircle
                            : LucideIcons.ticket,
                        color: appliedCode != null
                            ? AppColors.secondary
                            : AppColors.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appliedCode ?? 'Apply Coupon',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: appliedCode != null
                                  ? AppColors.secondary
                                  : AppColors.onSurface,
                            ),
                          ),
                          Text(
                            appliedCode != null
                                ? 'Saving ₹${discount.toStringAsFixed(0)} on this order'
                                : 'Tap to view available offers',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isValidatingCoupon.value)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      )
                    else if (appliedCode != null)
                      InkWell(
                        onTap: () {
                          ref.read(cartDiscountProvider.notifier).state = 0.0;
                          ref.read(appliedCouponCodeProvider.notifier).state =
                              null;
                        },
                        child: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppColors.outline,
                        ),
                      )
                    else
                      const Icon(
                        LucideIcons.chevronRight,
                        color: AppColors.outline,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Sticky summary + CTA ─────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _SummaryBar(
            subtotal: subtotal,
            deliveryFee: deliveryFee,
            discount: discount,
            total: total,
          ),
        ),
      ],
    );
  }
}

// ── Single cart item row ─────────────────────────────────────────────────────

class _CartItemRow extends HookConsumerWidget {
  final CartItem item;
  final CartNotifier notifier;

  const _CartItemRow({required this.item, required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpdating = useState(false);

    Future<void> changeQty(int delta) async {
      if (isUpdating.value) return;
      isUpdating.value = true;
      try {
        await notifier.updateQuantity(item.id, item.quantity + delta);
      } finally {
        isUpdating.value = false;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.product.imagePath.isNotEmpty
                ? AppNetworkImage(
                    imageUrl: item.product.imagePath,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const Icon(LucideIcons.image, color: AppColors.outline),
                  )
                : const Icon(
                    LucideIcons.shoppingBag,
                    color: AppColors.outline,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.onSurface,
                  ),
                ),
                if (item.product.unit != null && item.product.unit!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.product.unit!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${item.product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    // Quantity stepper
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StepButton(
                            icon: LucideIcons.minus,
                            color: AppColors.primary,
                            bg: AppColors.surfaceContainerLowest,
                            onTap: isUpdating.value
                                ? null
                                : () => changeQty(-1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: isUpdating.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                          ),
                          _StepButton(
                            icon: LucideIcons.plus,
                            color: AppColors.onPrimary,
                            bg: AppColors.primary,
                            onTap: isUpdating.value ? null : () => changeQty(1),
                          ),
                        ],
                      ),
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

class _StepButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;

  const _StepButton({
    required this.icon,
    required this.color,
    required this.bg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Sticky summary card ──────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;

  const _SummaryBar({
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                _SummaryRow(
                  'Delivery',
                  deliveryFee == 0
                      ? 'FREE'
                      : '₹${deliveryFee.toStringAsFixed(0)}',
                  valueColor: deliveryFee == 0 ? AppColors.secondary : null,
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 6),
                  _SummaryRow(
                    'Coupon Discount',
                    '-₹${discount.toStringAsFixed(0)}',
                    valueColor: AppColors.secondary,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.outlineVariant),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/checkout'),
                    icon: const Icon(LucideIcons.arrowRight, size: 20),
                    label: const Text(
                      'Proceed to Checkout',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6C3CE1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
