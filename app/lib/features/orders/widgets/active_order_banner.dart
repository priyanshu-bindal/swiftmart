import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/models/order_model.dart';
import '../providers/active_order_provider.dart';

const _primary = Color(0xFF0EA5E9);
const _primaryDark = Color(0xFF0284C7);

class ActiveOrderBanner extends ConsumerWidget {
  const ActiveOrderBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOrderAsync = ref.watch(activeOrderProvider);

    return activeOrderAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _err) => const SizedBox.shrink(),
      data: (order) {
        if (order == null) return const SizedBox.shrink();
        return _BannerContent(order: order);
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  final OrderModel order;
  const _BannerContent({required this.order});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: () => context.push('/order-detail/${order.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Animated status icon ─────────────────────────────────
              _AnimatedStatusIcon(status: order.status),

              const SizedBox(width: 12),

              // ── Text content ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusTitle(order.status),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusSubtitle(order.status),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── Track button ─────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Track',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .slideY(begin: -1, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 300.ms);
  }

  String _statusTitle(String status) {
    switch (status) {
      case 'CONFIRMED':
        return 'Order Confirmed! 📦';
      case 'PREPARING':
        return 'Packing your groceries 🧺';
      case 'OUT_FOR_DELIVERY':
        return 'Your order is on the way! 🚴';
      default:
        return 'Order in progress';
    }
  }

  String _statusSubtitle(String status) {
    switch (status) {
      case 'CONFIRMED':
        return 'Being prepared for you';
      case 'PREPARING':
        return 'Fresh items being packed';
      case 'OUT_FOR_DELIVERY':
        return 'Arriving soon — track live';
      default:
        return 'Sit tight!';
    }
  }
}

// ── Animated icon per status ──────────────────────────────────────────────────

class _AnimatedStatusIcon extends StatelessWidget {
  final String status;
  const _AnimatedStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: _buildIcon(),
      ),
    );
  }

  Widget _buildIcon() {
    switch (status) {
      case 'CONFIRMED':
        // Pulsing package icon
        return const Text('📦', style: TextStyle(fontSize: 22))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.2, 1.2),
              duration: 800.ms,
              curve: Curves.easeInOut,
            );
      case 'PREPARING':
        // Bouncing chef icon
        return const Text('👨‍🍳', style: TextStyle(fontSize: 22))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -4, duration: 600.ms, curve: Curves.easeInOut);
      case 'OUT_FOR_DELIVERY':
        // Sliding bike icon
        return const Text('🚴', style: TextStyle(fontSize: 22))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveX(begin: -4, end: 4, duration: 1000.ms, curve: Curves.easeInOut);
      default:
        return const Text('📋', style: TextStyle(fontSize: 22));
    }
  }
}
