import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import 'providers/coupons_provider.dart';
import 'widgets/coupon_card.dart';

class CouponsScreen extends HookConsumerWidget {
  final bool fromCart;

  const CouponsScreen({super.key, this.fromCart = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(couponsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      appBar: AppBar(
        title: Text(
          '🎟 Offers & Coupons',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        elevation: 0,
      ),
      body: state.when(
        data: (coupons) {
          if (coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_activity_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No coupons available right now',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: coupons.length,
            separatorBuilder: (_, _) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final couponModel = coupons[index];
              return CouponCard(coupon: couponModel, fromCart: fromCart)
                  .animate(delay: (100 * index).ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuart);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Failed to load coupons:\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(couponsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
