import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../cart/providers/cart_provider.dart';

enum _PaymentMethod { upi, card, cod }

class CheckoutScreen extends HookConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Form controllers ────────────────────────────────────────────────────
    final nameCtrl = useTextEditingController(text: 'Shadow');
    final phoneCtrl = useTextEditingController(text: '9876543210');
    final addressCtrl = useTextEditingController(text: '123 Fake Street');
    final cityCtrl = useTextEditingController(text: 'Mumbai');
    final pincodeCtrl = useTextEditingController(text: '400001');
    final formKey = useMemoized(GlobalKey<FormState>.new);

    // ── State ────────────────────────────────────────────────────────────────
    final paymentMethod = useState(_PaymentMethod.upi);
    final isPlacingOrder = useState(false);

    // ── Cart data ────────────────────────────────────────────────────────────
    final cartAsync = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final deliveryFee = ref.watch(cartDeliveryFeeProvider);
    final discount = ref.watch(cartDiscountProvider);
    final total = ref.watch(cartTotalProvider);
    final appliedCode = ref.watch(appliedCouponCodeProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    Future<void> placeOrder() async {
      if (!formKey.currentState!.validate()) return;
      if (cartAsync.value == null || cartAsync.value!.isEmpty) return;

      isPlacingOrder.value = true;
      try {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid == null) throw Exception('Not authenticated');

        final deliveryAddress = {
          'name': nameCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'address_line1': addressCtrl.text.trim(),
          'city': cityCtrl.text.trim(),
          'pincode': pincodeCtrl.text.trim(),
        };

        final cartItemsPayload = cartAsync.value!
            .map(
              (i) => {
                'product_id': i.productId,
                'quantity': i.quantity,
                'price': i.product.price,
              },
            )
            .toList();

        final methodStr = switch (paymentMethod.value) {
          _PaymentMethod.upi => 'upi',
          _PaymentMethod.card => 'card',
          _PaymentMethod.cod => 'cod',
        };

        final subtotal = ref.read(cartSubtotalProvider);
        final discount = ref.read(cartDiscountProvider);
        final total = ref.read(cartTotalProvider);

        String orderId = 'ORD-MOCK-123';
        try {
          final supabaseUid = Supabase.instance.client.auth.currentUser?.id;

          final response = await Supabase.instance.client
              .from('orders')
              .insert({
                // ignore: use_null_aware_elements
                if (supabaseUid != null) 'user_id': supabaseUid,
                'status': 'PENDING',
                'items': cartItemsPayload,
                'subtotal': subtotal,
                'discount': discount,
                'total': total,
                'coupon_code': appliedCode,
                'payment_method': methodStr,
                'delivery_address': deliveryAddress,
              })
              .select()
              .single();

          orderId = response['id']?.toString() ?? orderId;
        } catch (e) {
          debugPrint('Unable to insert order into DB (mock fallback used): $e');
        }

        await cartNotifier.clearCart();
        ref.read(cartDiscountProvider.notifier).state = 0.0;
        ref.read(appliedCouponCodeProvider.notifier).state = null;

        if (context.mounted) {
          context.pushReplacement(
            '/mock-payment',
            extra: {
              'order_id': orderId,
              'total': total,
              'payment_method': methodStr,
            },
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order failed: $e'),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: placeOrder,
              ),
            ),
          );
        }
      } finally {
        isPlacingOrder.value = false;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            // ── Section 1: Delivery Address ──────────────────────────────
            _SectionHeader(
              icon: LucideIcons.mapPin,
              title: 'Delivery Address',
            ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            _buildField(
              nameCtrl,
              'Full Name',
              LucideIcons.user,
              validator: _required,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            _buildField(
              phoneCtrl,
              'Phone Number',
              LucideIcons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  (v?.length ?? 0) < 10 ? 'Enter a valid phone number' : null,
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            _buildField(
              addressCtrl,
              'Address Line 1',
              LucideIcons.home,
              validator: _required,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    cityCtrl,
                    'City',
                    LucideIcons.building2,
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    pincodeCtrl,
                    'Pincode',
                    LucideIcons.mailbox,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (v?.length ?? 0) != 6 ? 'Enter 6-digit pincode' : null,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

            const SizedBox(height: 28),

            // ── Section 2: Order Summary ────────────────────────────────
            _SectionHeader(
              icon: LucideIcons.receipt,
              title: 'Order Summary',
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            cartAsync
                .when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  error: (e, _) => Text(
                    'Error: $e',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  data: (items) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  '× ${item.quantity}',
                                  style: const TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '₹${item.totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(color: AppColors.outlineVariant),
                        _OrderSummaryLine(
                          'Subtotal',
                          '₹${subtotal.toStringAsFixed(0)}',
                        ),
                        if (discount > 0)
                          _OrderSummaryLine(
                            'Discount',
                            '-₹${discount.toStringAsFixed(0)}',
                            color: AppColors.secondary,
                          ),
                        _OrderSummaryLine(
                          'Delivery',
                          deliveryFee == 0
                              ? 'FREE'
                              : '₹${deliveryFee.toStringAsFixed(0)}',
                          color: deliveryFee == 0 ? AppColors.secondary : null,
                        ),
                        const Divider(color: AppColors.outlineVariant),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              '₹${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 350.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: 28),

            // ── Section 3: Payment Method ───────────────────────────────
            _SectionHeader(
              icon: LucideIcons.wallet,
              title: 'Payment Method',
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            ..._PaymentMethod.values.map((method) {
              final isSelected = paymentMethod.value == method;
              return GestureDetector(
                onTap: () => paymentMethod.value = method,
                child: AnimatedContainer(
                  duration: 200.ms,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6C3CE1).withValues(alpha: 0.07)
                        : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6C3CE1)
                          : AppColors.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF6C3CE1)
                                : AppColors.outlineVariant,
                            width: isSelected ? 6 : 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        switch (method) {
                          _PaymentMethod.upi => LucideIcons.smartphone,
                          _PaymentMethod.card => LucideIcons.creditCard,
                          _PaymentMethod.cod => LucideIcons.banknote,
                        },
                        color: isSelected
                            ? const Color(0xFF6C3CE1)
                            : AppColors.outline,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        switch (method) {
                          _PaymentMethod.upi => 'UPI',
                          _PaymentMethod.card => 'Card',
                          _PaymentMethod.cod => 'Cash on Delivery',
                        },
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF6C3CE1)
                              : AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: _PlaceOrderBar(
        total: total,
        isLoading: isPlacingOrder.value,
        onPressed: placeOrder,
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.outline),
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C3CE1), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.primaryFixed,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _OrderSummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _OrderSummaryLine(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  final double total;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PlaceOrderBar({
    required this.total,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
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
                  backgroundColor: const Color(0xFF6C3CE1),
                  disabledBackgroundColor: const Color(
                    0xFF6C3CE1,
                  ).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Place Order  •  ₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
