import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/models/coupon_model.dart';
import '../../offers/providers/coupons_provider.dart';

class PromoCodeBottomSheet extends HookConsumerWidget {
  final double subtotal;

  const PromoCodeBottomSheet({super.key, required this.subtotal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(couponsProvider);
    final codeCtrl = useTextEditingController();
    final selectedCoupon = useState<CouponModel?>(null);
    final errorMsg = useState<String?>(null);

    void applyCoupon() {
      final code = codeCtrl.text.trim().toUpperCase();
      if (code.isEmpty) {
        errorMsg.value = 'Please enter a promo code';
        return;
      }

      final coupons = couponsAsync.asData?.value ?? [];
      final coupon = coupons.where((c) => c.code == code).firstOrNull;

      if (coupon == null) {
        errorMsg.value = 'Invalid promo code';
        return;
      }

      if (subtotal < coupon.minOrderValue) {
        errorMsg.value =
            'Minimum order value is ₹${coupon.minOrderValue.toStringAsFixed(0)}';
        return;
      }

      final discountAmt = coupon.computeDiscount(subtotal);
      errorMsg.value = null;
      Navigator.pop(context, {'code': coupon.code, 'discount': discountAmt});
    }

    void selectCoupon(CouponModel coupon) {
      selectedCoupon.value = coupon;
      codeCtrl.text = coupon.code;
      errorMsg.value = null;
    }

    void applySelected() {
      final coupon = selectedCoupon.value;
      if (coupon == null) {
        errorMsg.value = 'Please select a coupon';
        return;
      }
      if (subtotal < coupon.minOrderValue) {
        errorMsg.value =
            'Minimum order value is ₹${coupon.minOrderValue.toStringAsFixed(0)}';
        return;
      }
      final discountAmt = coupon.computeDiscount(subtotal);
      errorMsg.value = null;
      Navigator.pop(context, {'code': coupon.code, 'discount': discountAmt});
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Apply Promo Code',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Code input ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Enter code here',
                        hintStyle: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 1),
                    ),
                  ),
                  FilledButton(
                    onPressed: applyCoupon,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.skyBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('APPLY',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.white,
                            letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          ),

          // ── Error message ────────────────────────────────────────────
          if (errorMsg.value != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 24, right: 24),
              child: Text(errorMsg.value!,
                  style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),

          const SizedBox(height: 20),

          // ── Available Offers ──────────────────────────────────────────
          Expanded(
            child: couponsAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.skyBlue)),
              error: (e, _) => Center(
                  child:
                      Text('Error: $e', style: const TextStyle(color: Colors.red))),
              data: (coupons) {
                if (coupons.isEmpty) {
                  return const Center(
                      child: Text('No coupons available',
                          style: TextStyle(color: AppColors.onSurfaceVariant)));
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Available Offers',
                              style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppColors.onSurface)),
                          Text('${coupons.length} COUPONS FOUND',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warmOrange,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: coupons.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final coupon = coupons[index];
                          final isSelected =
                              selectedCoupon.value?.id == coupon.id;
                          return _CouponCard(
                            coupon: coupon,
                            isSelected: isSelected,
                            onTap: () => selectCoupon(coupon),
                          )
                              .animate(delay: (80 * index).ms)
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.08);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Apply Selected button ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: applySelected,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Apply Selected Coupon',
                      style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Coupon card inside bottom sheet ───────────────────────────────────────────

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CouponCard({
    required this.coupon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.skyBlue.withValues(alpha: 0.05)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.skyBlue : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warmOrange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                coupon.discountType == 'free_delivery'
                    ? LucideIcons.truck
                    : LucideIcons.tag,
                color: AppColors.warmOrange,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(coupon.code,
                          style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppColors.onSurface,
                              letterSpacing: 0.5)),
                      Text('TAP TO APPLY',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warmOrange,
                              letterSpacing: 0.3)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(coupon.description,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface)),
                  const SizedBox(height: 2),
                  Text(coupon.terms,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
