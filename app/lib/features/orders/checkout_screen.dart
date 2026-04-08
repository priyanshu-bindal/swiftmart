import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../cart/providers/cart_provider.dart';
import '../profile/providers/address_provider.dart';
import 'widgets/select_address_bottom_sheet.dart';

enum _PaymentMethod { cod, upi, card }

class CheckoutScreen extends HookConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethod = useState(_PaymentMethod.cod);
    final isPlacing = useState(false);

    final cartAsync = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryFee = ref.watch(cartDeliveryFeeProvider);
    final discount = ref.watch(cartDiscountProvider);
    final total = ref.watch(cartTotalProvider);
    final appliedCode = ref.watch(appliedCouponCodeProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final itemCount = cartAsync.asData?.value.fold<int>(0, (sum, i) => sum + i.quantity) ?? 0;

    Future<void> placeOrder() async {
      if (selectedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a delivery address'),
              backgroundColor: AppColors.error),
        );
        return;
      }
      if (cartAsync.value == null || cartAsync.value!.isEmpty) return;

      isPlacing.value = true;
      try {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid == null) throw Exception('Not authenticated');

        final methodStr = switch (paymentMethod.value) {
          _PaymentMethod.cod => 'cod',
          _PaymentMethod.upi => 'upi',
          _PaymentMethod.card => 'card',
        };

        // Snapshot cart items BEFORE clearing the cart.
        final orderItemsData = cartAsync.value!
            .map((i) => {
                  'product_id': i.productId,
                  'name': i.product?.name ?? '',
                  'image_url': i.product?.primaryImage ?? '',
                  'unit': i.product?.unit ?? '',
                  'quantity': i.quantity,
                  'unit_price': i.product?.salePrice ?? 0.0,
                  'total_price': i.totalPrice,
                })
            .toList();

        // Clear cart & discount state immediately for good UX.
        await cartNotifier.clearCart();
        ref.read(cartDiscountProvider.notifier).state = 0.0;
        ref.read(appliedCouponCodeProvider.notifier).state = null;

        // Navigate to payment — NO DB write yet.
        // The order is inserted into Supabase only after the user
        // confirms payment in MockPaymentScreen.
        if (context.mounted) {
          context.pushReplacement('/mock-payment', extra: {
            'uid': uid,
            'subtotal': subtotal,
            'delivery_fee': deliveryFee,
            'discount': discount,
            'total': total,
            'coupon_code': appliedCode,
            'payment_method': methodStr,
            'address_id': selectedAddress!.id,
            'delivery_address': {
              'label': selectedAddress!.label,
              'full_address': selectedAddress!.formattedAddress,
            },
            'order_items': orderItemsData,
          });
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to proceed: $e'),
                backgroundColor: AppColors.error),
          );
        }
      } finally {
        isPlacing.value = false;
      }
    }

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
        title: const Text('Checkout',
            style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: AppColors.onSurface)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          // ── Delivery Address ───────────────────────────────────────
          const Text('Delivery Address',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.onSurface))
              .animate()
              .fadeIn(delay: 50.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 12),

          _AddressSection(
            address: selectedAddress,
            onChangeTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const SelectAddressBottomSheet(),
              );
            },
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

          const SizedBox(height: 28),

          // ── Payment Method ─────────────────────────────────────────
          const Text('Payment Method',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.onSurface))
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 12),

          ..._PaymentMethod.values.asMap().entries.map((entry) {
            final idx = entry.key;
            final method = entry.value;
            final isSelected = paymentMethod.value == method;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PaymentTile(
                method: method,
                isSelected: isSelected,
                onTap: () => paymentMethod.value = method,
              ).animate(delay: (250 + idx * 50).ms).fadeIn().slideY(begin: 0.08),
            );
          }),

          const SizedBox(height: 28),

          // ── Order Summary ──────────────────────────────────────────
          const Text('Order Summary',
                  style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.onSurface))
              .animate()
              .fadeIn(delay: 400.ms)
              .slideY(begin: 0.1),
          const SizedBox(height: 12),

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
                _SummaryLine(
                    'Items count ($itemCount)', '₹${subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _SummaryLine(
                    'Delivery fee', '₹${deliveryFee.toStringAsFixed(2)}'),
                if (discount > 0) ...[
                  const SizedBox(height: 6),
                  _SummaryLine('Discount', '-₹${discount.toStringAsFixed(2)}',
                      color: AppColors.warmOrange),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: _DashedLinePainter(),
                  ),
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
                            color: AppColors.warmOrange)),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),

          const SizedBox(height: 20),

          // ── Info chips ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.sparkles,
                          size: 18, color: AppColors.skyBlue),
                      const SizedBox(height: 6),
                      Text('Earning ${(total * 0.1).toInt()} Reward\nPoints',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                              height: 1.3)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(LucideIcons.clock, size: 18, color: AppColors.skyBlue),
                      SizedBox(height: 6),
                      Text('Delivery in 8-15\nMins',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                              height: 1.3)),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
        ],
      ),
      bottomNavigationBar: _PlaceOrderBar(
        total: total,
        isLoading: isPlacing.value,
        onPressed: placeOrder,
      ),
    );
  }
}

// ── Address section ──────────────────────────────────────────────────────────

class _AddressSection extends StatelessWidget {
  final dynamic address; // AddressModel?
  final VoidCallback onChangeTap;

  const _AddressSection({required this.address, required this.onChangeTap});

  @override
  Widget build(BuildContext context) {
    if (address == null) {
      return GestureDetector(
        onTap: onChangeTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.skyBlue.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.mapPin, color: AppColors.skyBlue, size: 20),
              const SizedBox(width: 8),
              Text('Select Delivery Address',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.skyBlue)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.skyBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              address.label == 'Home'
                  ? LucideIcons.home
                  : address.label == 'Work'
                      ? LucideIcons.briefcase
                      : LucideIcons.mapPin,
              size: 18,
              color: AppColors.skyBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(address.label,
                        style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.onSurface)),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warmOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('DEFAULT',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.warmOrange,
                                letterSpacing: 0.8)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(address.formattedAddress,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onChangeTap,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Change',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.warmOrange)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment tile ─────────────────────────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  final _PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentTile(
      {required this.method, required this.isSelected, required this.onTap});

  IconData get _icon => switch (method) {
        _PaymentMethod.cod => LucideIcons.banknote,
        _PaymentMethod.upi => LucideIcons.smartphone,
        _PaymentMethod.card => LucideIcons.creditCard,
      };

  String get _label => switch (method) {
        _PaymentMethod.cod => 'Cash on Delivery',
        _PaymentMethod.upi => 'UPI (GPay / PhonePe)',
        _PaymentMethod.card => 'Credit or Debit Card',
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.skyBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                  color: AppColors.skyBlue.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.skyBlue.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(_icon,
                  size: 18,
                  color:
                      isSelected ? AppColors.skyBlue : Colors.grey.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected
                          ? AppColors.skyBlue
                          : AppColors.onSurface)),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.skyBlue
                      : Colors.grey.shade300,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary line ─────────────────────────────────────────────────────────────

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryLine(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.onSurfaceVariant)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.onSurface)),
      ],
    );
  }
}

// ── Dashed line painter ──────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
          Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ── Place Order bar ──────────────────────────────────────────────────────────

class _PlaceOrderBar extends StatelessWidget {
  final double total;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PlaceOrderBar(
      {required this.total, required this.isLoading, required this.onPressed});

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
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.skyBlue,
              disabledBackgroundColor: AppColors.skyBlue.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Place Order',
                          style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.white)),
                      SizedBox(width: 6),
                      Icon(LucideIcons.chevronRight,
                          size: 18, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
