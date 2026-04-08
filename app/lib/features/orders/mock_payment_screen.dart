import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';

class MockPaymentScreen extends HookWidget {
  /// All data required to create the order in Supabase.
  /// Passed from CheckoutScreen so the DB write happens AFTER payment.
  final Map<String, dynamic> orderData;

  const MockPaymentScreen({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    final isProcessing = useState(false);

    // Convenience getters read from orderData
    final double total = (orderData['total'] as num?)?.toDouble() ?? 0.0;
    final String paymentMethod =
        orderData['payment_method']?.toString() ?? 'upi';

    Future<void> processPayment() async {
      isProcessing.value = true;
      // Simulate payment gateway delay
      await Future.delayed(const Duration(seconds: 2));
      try {
        final supabase = Supabase.instance.client;

        // 1) Insert the order row — status CONFIRMED only NOW after payment
        final orderResponse = await supabase.from('orders').insert({
          'user_id': orderData['uid'],
          'status': 'CONFIRMED',
          'subtotal': orderData['subtotal'],
          'delivery_fee': orderData['delivery_fee'],
          'discount_amount': orderData['discount'],
          'total': orderData['total'],
          'coupon_code': orderData['coupon_code'],
          'payment_method': orderData['payment_method'],
          'address_id': orderData['address_id'],
          'delivery_address': orderData['delivery_address'],
        }).select().single();

        final orderId = orderResponse['id'].toString();

        // 2) Insert order items with the newly created order_id
        final rawItems = orderData['order_items'] as List<dynamic>;
        final itemsPayload = rawItems.map((item) {
          return Map<String, dynamic>.from(item as Map)
            ..['order_id'] = orderId;
        }).toList();
        await supabase.from('order_items').insert(itemsPayload);

        if (context.mounted) {
          context.pushReplacement(
              '/order-success', extra: {'order_id': orderId});
        }
      } catch (e) {
        isProcessing.value = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Payment failed: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: isProcessing.value
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.primary,
                ),
                onPressed: () => context.pop(),
              ),
        title: const Text(
          'Payment',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ── Payment UI ───────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              child: switch (paymentMethod) {
                'card' => _CardPaymentView(total: total, onPay: processPayment),
                'cod' => _CodPaymentView(
                  total: total,
                  onConfirm: processPayment,
                ),
                _ => _UpiPaymentView(total: total, onPay: processPayment),
              },
            ),
          ),

          // ── Processing overlay ────────────────────────────────────────────
          if (isProcessing.value)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: AppColors.background.withValues(alpha: 0.85),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Processing payment…',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.onSurface,
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 8),
                      const Text(
                        'Please do not go back',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── UPI View ─────────────────────────────────────────────────────────────────

class _UpiPaymentView extends StatelessWidget {
  final double total;
  final VoidCallback onPay;

  const _UpiPaymentView({required this.total, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C3CE1), Color(0xFF006B55)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C3CE1).withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.smartphone,
            color: Colors.white,
            size: 44,
          ),
        ).animate().scale(curve: Curves.elasticOut, duration: 700.ms),
        const SizedBox(height: 24),
        const Text(
          'Pay via UPI',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: AppColors.onSurface,
          ),
        ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryFixed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.link, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'swiftmart@upi',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ).animate(delay: 200.ms).fadeIn(),
        const SizedBox(height: 40),
        _AmountDisplay(total: total),
        const SizedBox(height: 40),
        _PayButton(label: 'Pay ₹${total.toStringAsFixed(0)}', onPay: onPay),
      ],
    );
  }
}

// ── Card View ─────────────────────────────────────────────────────────────────

class _CardPaymentView extends HookWidget {
  final double total;
  final VoidCallback onPay;

  const _CardPaymentView({required this.total, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final cardNum = useTextEditingController();
    final expiry = useTextEditingController();
    final cvv = useTextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        // Card chip graphic
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C3CE1), Color(0xFF3B1FA8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C3CE1).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Icon(LucideIcons.wifi, color: Colors.white54, size: 20),
                ],
              ),
              const Spacer(),
              const Text(
                '•••• •••• •••• ••••',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  letterSpacing: 3,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'SWIFTMART CARD',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
        const SizedBox(height: 28),
        _CardField(
          ctrl: cardNum,
          label: 'Card Number',
          formatter: _CardNumberFormatter(),
          maxLen: 19,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CardField(
                ctrl: expiry,
                label: 'MM / YY',
                formatter: _ExpiryFormatter(),
                maxLen: 5,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _CardField(
                ctrl: cvv,
                label: 'CVV',
                maxLen: 4,
                obscure: true,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _AmountDisplay(total: total),
        const SizedBox(height: 28),
        _PayButton(label: 'Pay ₹${total.toStringAsFixed(0)}', onPay: onPay),
      ],
    );
  }
}

class _CardField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputFormatter? formatter;
  final int? maxLen;
  final bool obscure;
  final TextInputType? keyboardType;

  const _CardField({
    required this.ctrl,
    required this.label,
    this.formatter,
    this.maxLen,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLength: maxLen,
      inputFormatters: formatter != null ? [formatter!] : null,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
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
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue value,
  ) {
    final digits = value.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return value.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue value,
  ) {
    final digits = value.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return value.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

// ── COD View ─────────────────────────────────────────────────────────────────

class _CodPaymentView extends StatelessWidget {
  final double total;
  final VoidCallback onConfirm;

  const _CodPaymentView({required this.total, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.banknote,
            size: 52,
            color: AppColors.secondary,
          ),
        ).animate().scale(curve: Curves.elasticOut, duration: 700.ms),
        const SizedBox(height: 28),
        const Text(
          'Cash on Delivery',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: AppColors.onSurface,
          ),
        ).animate(delay: 100.ms).fadeIn(),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Pay ₹${total.toStringAsFixed(0)} to the delivery partner when your order arrives.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ).animate(delay: 200.ms).fadeIn(),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.info,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Please keep exact change ready. Delivery partners may not carry change for large bills.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 40),
        _AmountDisplay(total: total),
        const SizedBox(height: 32),
        _PayButton(label: 'Confirm Order', onPay: onConfirm),
      ],
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _AmountDisplay extends StatelessWidget {
  final double total;
  const _AmountDisplay({required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Amount to Pay',
          style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${total.toStringAsFixed(0)}',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w900,
            fontSize: 36,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _PayButton extends StatelessWidget {
  final String label;
  final VoidCallback onPay;

  const _PayButton({required this.label, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPay,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6C3CE1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF6C3CE1).withValues(alpha: 0.4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15);
  }
}
