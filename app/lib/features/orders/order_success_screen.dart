import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';

class OrderSuccessScreen extends HookWidget {
  final String? orderId;

  const OrderSuccessScreen({super.key, this.orderId});

  @override
  Widget build(BuildContext context) {
    // 3-step animation sequence: confirming → check → full screen
    final step = useState(1);
    final showTrackPulse = useState(false);

    useEffect(() {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (context.mounted) step.value = 2;
      });
      Future.delayed(const Duration(milliseconds: 2800), () {
        if (context.mounted) step.value = 3;
      });
      Future.delayed(const Duration(milliseconds: 6000), () {
        if (context.mounted) showTrackPulse.value = true;
      });
      return null;
    }, const []);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        child: switch (step.value) {
          1 => _buildConfirming(),
          2 => _buildCheckmark(),
          _ => _buildSuccessScreen(
            context,
            orderId: orderId,
            showTrackPulse: showTrackPulse.value,
          ),
        },
      ),
    );
  }

  Widget _buildConfirming() {
    return SizedBox.expand(
      key: const ValueKey('step1'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Confirming your order…',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.primary,
            ),
          ).animate().fadeIn(duration: 300.ms),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildCheckmark() {
    return SizedBox.expand(
      key: const ValueKey('step2'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: Colors.white,
                  size: 44,
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.3, 0.3),
                curve: Curves.elasticOut,
                duration: 800.ms,
              )
              .fadeIn(duration: 200.ms),
          const SizedBox(height: 24),
          const Text(
            'OrderModel Confirmed!',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: AppColors.onSurface,
            ),
          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(
    BuildContext context, {
    String? orderId,
    bool showTrackPulse = false,
  }) {
    return SizedBox.expand(
      key: const ValueKey('step3'),
      child: Stack(
        children: [
          // ── Flutter-animate confetti particles ───────────────────────
          _ConfettiLayer(),

          // ── Main content ─────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),
                          // Animated checkmark
                          Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.secondaryContainer,
                                      AppColors.secondary,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.secondary.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 28,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  LucideIcons.check,
                                  color: Colors.white,
                                  size: 52,
                                ),
                              )
                              .animate()
                              .scale(
                                begin: const Offset(0.6, 0.6),
                                curve: Curves.elasticOut,
                                duration: 900.ms,
                              )
                              .fadeIn(duration: 300.ms),

                          const SizedBox(height: 28),

                          const Text(
                            'OrderModel Placed! 🎉',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w900,
                              fontSize: 30,
                              color: AppColors.onSurface,
                            ),
                          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),

                          const SizedBox(height: 8),

                          const Text(
                            'Your groceries are on the way!',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),

                          const SizedBox(height: 36),

                          // Info cards row
                          Row(
                            children: [
                              Expanded(
                                child: _InfoCard(
                                  icon: LucideIcons.receipt,
                                  title: 'OrderModel ID',
                                  value: orderId != null
                                      ? '#${orderId.substring(0, min(8, orderId.length)).toUpperCase()}'
                                      : '#—',
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: _InfoCard(
                                  icon: LucideIcons.clock,
                                  title: 'Estimated',
                                  value: '20-30 min',
                                ),
                              ),
                            ],
                          ).animate(delay: 450.ms).fadeIn().slideY(begin: 0.1),

                          const SizedBox(height: 20),

                          // Delivery blurb card
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.05,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryFixed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.bike,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Delivery partner assigned',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Your OrderModel is being packed and will be dispatched shortly',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Action buttons ────────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Track OrderModel (primary) — pulses after 3s
                      AnimatedBuilder(
                        animation: const AlwaysStoppedAnimation(0),
                        builder: (context, _) {
                          Widget btn = SizedBox(
                            height: 56,
                            child: FilledButton.icon(
                              onPressed: () => context.push('/OrderModel-tracking'),
                              icon: const Icon(LucideIcons.mapPin, size: 18),
                              label: const Text(
                                'Track OrderModel',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                            ),
                          );
                          if (showTrackPulse) {
                            btn = btn
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scaleXY(
                                  end: 1.03,
                                  duration: 1200.ms,
                                  curve: Curves.easeInOut,
                                );
                          }
                          return btn;
                        },
                      ),
                      const SizedBox(height: 12),
                      // Continue Shopping (secondary)
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => context.go('/home'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Continue Shopping',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate(delay: 800.ms).fadeIn().slideY(begin: 0.15),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confetti layer using flutter_animate ─────────────────────────────────────

class _ConfettiLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rng = Random(42);
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      const Color(0xFFFBBC04),
      const Color(0xFFEA4335),
      const Color(0xFF34A853),
      const Color(0xFFCEBDFF),
    ];

    return IgnorePointer(
      child: Stack(
        children: List.generate(32, (i) {
          final x = rng.nextDouble() * 400;
          final y = rng.nextDouble() * 300 - 60;
          final size = 6.0 + rng.nextDouble() * 8;
          final color = colors[i % colors.length];
          final isSquare = i % 3 == 0;
          final delayMs = rng.nextInt(600);

          return Positioned(
            left: x,
            top: y,
            child:
                Container(
                      width: size,
                      height: isSquare ? size : size * 0.5,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.75),
                        borderRadius: isSquare
                            ? BorderRadius.circular(2)
                            : BorderRadius.circular(size),
                      ),
                    )
                    .animate(delay: delayMs.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(
                      begin: -0.5,
                      end: 1.2,
                      duration: 1800.ms,
                      curve: Curves.easeIn,
                    )
                    .then()
                    .fadeOut(duration: 600.ms),
          );
        }),
      ),
    );
  }
}

// ── Info card widget ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
