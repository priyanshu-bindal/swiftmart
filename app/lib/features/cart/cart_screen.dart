import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import 'providers/cart_provider.dart';

class CouponNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void applyCoupon(String coupon) {
    state = coupon;
  }
}

final couponProvider = NotifierProvider<CouponNotifier, String?>(CouponNotifier.new);

class CartScreen extends HookConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final selectedCoupon = ref.watch(couponProvider);

    double subtotal = cartNotifier.totalAmount;
    double discount = selectedCoupon != null ? 2.00 : 0.00;
    double deliveryFee = cartItems.isNotEmpty ? 1.50 : 0.00;
    double totalAmount = subtotal + deliveryFee - discount;
    if (totalAmount < 0) totalAmount = 0;

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
                icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
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
                IconButton(
                  icon: const Icon(LucideIcons.moreVertical, color: AppColors.outline),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('Your basket is empty', style: TextStyle(color: AppColors.outline)))
          : ListView(
              padding: const EdgeInsets.only(top: 100, left: 24, right: 24, bottom: 140),
              children: [
                // Cart Items
                ...cartItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Dismissible(
                    key: Key(item.product.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) => cartNotifier.removeProductCompletely(item.product.id),
                    background: Container(
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(LucideIcons.trash2, color: AppColors.onError),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          // Image
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: item.product.imagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.product.unit ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '\$${item.product.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () => cartNotifier.removeProduct(item.product.id),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: AppColors.surfaceContainerLowest,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(LucideIcons.minus, size: 16, color: AppColors.primary),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          InkWell(
                                            onTap: () => cartNotifier.addProduct(item.product),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(LucideIcons.plus, size: 16, color: AppColors.onPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )),

                // Coupon Card
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showCouponSheet(context, ref),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.ticket, color: AppColors.onSecondaryContainer),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedCoupon ?? 'Apply Coupon', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                              Text(selectedCoupon != null ? 'Coupon applied' : 'Save \$2.00 on this order', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary)),
                            ],
                          ),
                        ),
                        const Icon(LucideIcons.chevronRight, color: AppColors.outline),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                
                // Delivery Address
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: const BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.home, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Home', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                                InkWell(
                                  onTap: () {},
                                  child: const Text('Change', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                                )
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '123 Maple Street, Apartment 4B\nGreenview Gardens, NY 10012',
                              style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant, height: 1.5),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // Payment Method
                const Text(
                  'Payment Method',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      _buildPaymentPill(LucideIcons.wallet, 'UPI', isSelected: true),
                      const SizedBox(width: 16),
                      _buildPaymentPill(LucideIcons.creditCard, 'Card'),
                      const SizedBox(width: 16),
                      _buildPaymentPill(LucideIcons.banknote, 'Cash'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Bill Summary
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bill Summary', style: TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(color: AppColors.onSurfaceVariant)),
                          Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery Fee', style: TextStyle(color: AppColors.onSurfaceVariant)),
                          Text('\$${deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(LucideIcons.gift, size: 16, color: AppColors.secondary),
                              SizedBox(width: 4),
                              Text('Discount', style: TextStyle(color: AppColors.secondary)),
                            ],
                          ),
                          Text('-\$${discount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(color: AppColors.outlineVariant),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.onSurface)),
                          Text('\$${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomSheet: cartItems.isEmpty ? null : _buildBottomBar(context, ref, totalAmount),
    );
  }

  Widget _buildPaymentPill(IconData icon, String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected 
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] 
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? AppColors.onPrimary : AppColors.onSurface),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.onPrimary : AppColors.onSurface)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, double totalAmount) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, -8),
              )
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL PAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.onSurfaceVariant, letterSpacing: 1.2)),
                    Text('\$${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.onSurface)),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      ref.read(cartProvider.notifier).clearCart();
                      context.pushReplacement('/order-success');
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Place Order', style: TextStyle(color: AppColors.onPrimary, fontFamily: 'Manrope', fontWeight: FontWeight.w900, fontSize: 18)),
                          SizedBox(width: 8),
                          Icon(LucideIcons.arrowRight, color: AppColors.onPrimary),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCouponSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Available Coupons', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Manrope')),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.tag, color: AppColors.secondary),
                title: const Text('SAVE200', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Save \$2.00 on this order'),
                trailing: TextButton(
                  onPressed: () {
                    ref.read(couponProvider.notifier).applyCoupon('SAVE200');
                    Navigator.pop(context);
                  },
                  child: const Text('Apply', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
