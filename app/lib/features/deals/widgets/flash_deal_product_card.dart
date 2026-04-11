import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../cart/providers/cart_provider.dart';
import '../../../shared/providers/cart_toast_provider.dart';
import '../providers/flash_deal_price_provider.dart';

class FlashDealProductCard extends HookConsumerWidget {
  final Map<String, dynamic> item;
  final num? baseDiscountPercent;

  const FlashDealProductCard({required this.item, this.baseDiscountPercent, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = item['products'];
    if (product == null) return const SizedBox.shrink();

    final productId = product['id']?.toString() ?? '';
    final name = product['name'] ?? 'Unknown Item';
    final imageUrl = product['image_url'] ?? '';
    final unitSize = product['unit_size'] ?? '';
    final unit = product['unit'] ?? '';
    final originalPrice = num.tryParse(product['sale_price']?.toString() ?? '0') ?? 0;

    // Calculate deal price
    final overridePriceRaw = item['override_price'];
    num dealPrice;
    if (overridePriceRaw != null) {
      dealPrice = num.tryParse(overridePriceRaw.toString()) ?? originalPrice;
    } else {
      final discount = baseDiscountPercent ?? 0;
      dealPrice = originalPrice * (1 - (discount / 100));
    }

    final savingsPercent = originalPrice > 0
        ? (((originalPrice - dealPrice) / originalPrice) * 100).round()
        : 0;

    // Watch cart state for this product
    final cartItems = ref.watch(cartProvider).asData?.value ?? [];
    final cartItem = cartItems.where((i) => i.productId == productId).firstOrNull;
    final quantity = cartItem?.quantity ?? 0;

    return GestureDetector(
      onTap: () {
        if (productId.isNotEmpty) context.push('/ProductModel/$productId');
      },
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                Container(color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey)),
                          )
                        : Container(color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey)),
                  ),
                  // Savings badge
                  if (savingsPercent > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$savingsPercent% OFF',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.2),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$unitSize $unit'.trim(),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                  const SizedBox(height: 4),

                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${dealPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF006B5C),
                            fontSize: 15,
                          ),
                        ),
                        if (originalPrice > dealPrice) ...[
                          const SizedBox(width: 4),
                          Text(
                            '₹${originalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ADD / Stepper Button
                    quantity == 0
                        ? _AddButton(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              if (productId.isNotEmpty) {
                                // Store the deal price override before adding to cart
                                ref.read(flashDealPriceProvider.notifier)
                                    .setOverride(productId, dealPrice.toDouble());
                                ref.read(cartProvider.notifier).addToCart(productId);
                                ref.read(cartToastProvider.notifier).show(
                                  productName: name,
                                  productImage: imageUrl.isNotEmpty ? imageUrl : null,
                                );
                              }
                            },
                          )
                        : _StepperButton(
                            quantity: quantity,
                            onIncrement: () {
                              HapticFeedback.lightImpact();
                              ref.read(cartProvider.notifier).addToCart(productId);
                            },
                            onDecrement: () {
                              if (cartItem != null) {
                                ref.read(cartProvider.notifier).decrementItem(cartItem);
                              }
                            },
                          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF006B5C), width: 1.2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: const Text(
          'ADD',
          style: TextStyle(
            color: Color(0xFF006B5C),
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _StepperButton({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF006B5C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onDecrement,
              child: const Center(child: Icon(Icons.remove, color: Colors.white, size: 14)),
            ),
          ),
          Text(
            '$quantity',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onIncrement,
              child: const Center(child: Icon(Icons.add, color: Colors.white, size: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
