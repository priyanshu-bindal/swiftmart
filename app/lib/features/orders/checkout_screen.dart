import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_button.dart';
import '../cart/providers/cart_provider.dart';

class CheckoutScreen extends HookConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final isLoading = useState(false);

    void simulatePayment() async {
      isLoading.value = true;
      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        isLoading.value = false;
        ref.read(cartProvider.notifier).clearCart();
        context.pushReplacement('/order-success');
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout', style: TextStyle(color: AppColors.primary))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Total Items: ${cartItems.length}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 32),
              AppButton(
                text: 'Pay Mock',
                isLoading: isLoading.value,
                onPressed: cartItems.isEmpty ? () => context.go('/') : simulatePayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

