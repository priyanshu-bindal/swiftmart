import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:app/shared/widgets/app_network_image.dart';

import '../../core/theme/app_colors.dart';
import 'package:app/core/models/cart_item_model.dart';
import 'providers/cart_provider.dart';
import 'widgets/promo_code_bottom_sheet.dart';

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

    return Scaffold(
      backgroundColor: AppColors.cleanBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cleanBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Your Cart',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: cartAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.skyBlue),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertCircle,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                const Text('Failed to load cart',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => ref.invalidate(cartProvider),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) return _EmptyCartView();
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
                    color: AppColors.skyBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.shoppingCart,
                      size: 56, color: AppColors.skyBlue),
                )
                .animate()
                .scale(
                    begin: const Offset(0.5, 0.5),
                    curve: Curves.elasticOut,
                    duration: 700.ms)
                .fadeIn(),
            const SizedBox(height: 32),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.onSurface),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text(
              'Browse our products and add\nsomething delicious!',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.onSurfaceVariant, height: 1.5),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(LucideIcons.shoppingBag, size: 18),
              label: const Text('Shop Now',
                  style: TextStyle(
                      fontFamily: 'Manrope', fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.skyBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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

// ── Cart body with items + sticky bottom ─────────────────────────────────────

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
    final notifier = ref.read(cartProvider.notifier);
    final showConfetti = useState(false);
    final confettiKey = useState(UniqueKey());

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  // ── Cart items ─────────────────────────────────────────
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CartItemCard(item: item, notifier: notifier)
                          .animate(delay: (60 * idx).ms)
                          .fadeIn(duration: 300.ms)
                          .slideX(begin: -0.04),
                    );
                  }),

                  const SizedBox(height: 8),

                  // ── Apply Promo Code row ───────────────────────────────
                  InkWell(
                    onTap: () => _openPromoSheet(context, ref, showConfetti, confettiKey),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.skyBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              appliedCode != null
                                  ? LucideIcons.checkCircle
                                  : LucideIcons.tag,
                              color: AppColors.skyBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              appliedCode != null
                                  ? 'Coupon "$appliedCode" applied'
                                  : 'Apply Promo Code',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: appliedCode != null
                                    ? AppColors.skyBlue
                                    : AppColors.onSurface,
                              ),
                            ),
                          ),
                          if (appliedCode != null)
                            GestureDetector(
                              onTap: () {
                                ref.read(cartDiscountProvider.notifier).state = 0.0;
                                ref.read(appliedCouponCodeProvider.notifier).state =
                                    null;
                              },
                              child: const Icon(LucideIcons.x,
                                  size: 18, color: AppColors.outline),
                            )
                          else
                            const Icon(LucideIcons.chevronRight,
                                color: AppColors.outline),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Price breakdown ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _PriceRow(
                            'Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _PriceRow(
                            'Delivery Fee', '₹${deliveryFee.toStringAsFixed(2)}'),
                        if (discount > 0) ...[
                          const SizedBox(height: 8),
                          _PriceRow(
                            'Discount',
                            '-₹${discount.toStringAsFixed(2)}',
                            valueColor: AppColors.warmOrange,
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child:
                              Divider(height: 1, color: AppColors.outlineVariant),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount',
                                style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: AppColors.onSurface)),
                            Text('₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: AppColors.skyBlue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Sticky bottom bar ────────────────────────────────────────
            _BottomBar(total: total),
          ],
        ),

        // ── Confetti overlay ──────────────────────────────────────────
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
        ref.read(appliedCouponCodeProvider.notifier).state =
            result['code'] as String;
        ref.read(cartDiscountProvider.notifier).state =
            result['discount'] as double;

        // 🎉 Trigger celebration confetti + haptic
        HapticFeedback.mediumImpact();
        confettiKey.value = UniqueKey();
        showConfetti.value = true;
      }
    });
  }
}

// ── Single cart item card ─────────────────────────────────────────────────────

class _CartItemCard extends HookConsumerWidget {
  final CartItemModel item;
  final CartNotifier notifier;

  const _CartItemCard({required this.item, required this.notifier});

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              // Product image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.product?.primaryImage?.isNotEmpty == true
                    ? AppNetworkImage(
                        imageUrl: item.product!.primaryImage!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(
                            LucideIcons.image,
                            color: AppColors.outline),
                      )
                    : const Icon(LucideIcons.shoppingBag,
                        color: AppColors.outline, size: 32),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product?.name ?? 'Unknown item',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (item.product?.brand != null &&
                        item.product!.brand!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.product!.brand!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    if (item.product?.unit != null &&
                        item.product!.unit!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          item.product!.unit!,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${(item.product?.salePrice ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.skyBlue,
                          ),
                        ),
                        // Quantity stepper
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _StepBtn(
                                icon: LucideIcons.minus,
                                color: AppColors.onSurface,
                                bg: Colors.white,
                                onTap: isUpdating.value
                                    ? null
                                    : () => changeQty(-1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: isUpdating.value
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.skyBlue))
                                    : Text('${item.quantity}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.onSurface)),
                              ),
                              _StepBtn(
                                icon: LucideIcons.plus,
                                color: Colors.white,
                                bg: AppColors.skyBlue,
                                onTap: isUpdating.value
                                    ? null
                                    : () => changeQty(1),
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
          // Remove X button — top right
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => notifier.removeFromCart(item.id),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.x, size: 14, color: Colors.grey),
              ),
            ),
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Price row ─────────────────────────────────────────────────────────────────

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PriceRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: AppColors.onSurfaceVariant)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.onSurface)),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left: total
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('TOTAL TO PAY',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text('₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: AppColors.onSurface)),
                ],
              ),
            ),
            // Right: checkout button
            FilledButton(
              onPressed: () => context.push('/checkout'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.skyBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Proceed to Checkout',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white)),
                  SizedBox(width: 6),
                  Icon(LucideIcons.arrowRight, size: 18, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coupon celebration confetti overlay ───────────────────────────────────────

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
    Color(0xFF0EA5E9), // sky blue
    Color(0xFFF97316), // warm orange
    Color(0xFF22C55E), // green
    Color(0xFFFBBC04), // yellow
    Color(0xFFEC4899), // pink
    Color(0xFFA855F7), // purple
    Color(0xFF14B8A6), // teal
    Color(0xFFEF4444), // red
  ];

  final _rng = Random();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward().whenComplete(() {
        widget.onComplete();
      });

    _particles = List.generate(48, (i) {
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
              // ── Particles ──────────────────────────────────────────────
              ..._particles.map((p) {
                final progress =
                    ((t - p.delay) / p.speed).clamp(0.0, 1.0);
                if (progress <= 0) return const SizedBox.shrink();

                final opacity =
                    progress < 0.15 ? progress / 0.15 : (1 - progress);
                final top = -20.0 + (size.height + 40) * progress;
                final left =
                    size.width * p.x + sin(progress * pi * 3) * size.width * p.sway;

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

              // ── "🎉 Coupon Applied!" banner ────────────────────────────
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
                            colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF0EA5E9).withValues(alpha: 0.4),
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
  final double x;
  final double size;
  final Color color;
  final double delay;
  final double speed;
  final bool isSquare;
  final double sway;
  final double rotation;

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
