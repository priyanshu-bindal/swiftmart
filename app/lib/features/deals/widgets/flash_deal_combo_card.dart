import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/models/product_model.dart';
import '../../cart/providers/cart_provider.dart';

/// A card displaying two products bundled into a combo deal.
/// Shows crossed-out regular price, combo price, and an "Add Combo" button.
class FlashDealComboCard extends HookConsumerWidget {
  final ProductModel productA;
  final ProductModel productB;

  /// Optional override label shown on the badge. Defaults to comboDeal.label.
  final String? label;

  const FlashDealComboCard({
    required this.productA,
    required this.productB,
    this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdding = useState(false);

    // Combo prices
    final aPriceCombo = productA.comboDeal?.thisItemComboPrice ?? productA.salePrice;
    final bPriceCombo = productB.comboDeal?.thisItemComboPrice ?? productB.salePrice;
    final comboTotal = aPriceCombo + bPriceCombo;
    final regularTotal = productA.salePrice + productB.salePrice;
    final savings = regularTotal - comboTotal;
    final savingsPct = regularTotal > 0 ? ((savings / regularTotal) * 100).round() : 0;

    final dealLabel = label ??
        productA.comboDeal?.label ??
        '${productA.name} + ${productB.name} Combo';

    // Check if this combo is already in the cart
    final cartItems = ref.watch(cartProvider).asData?.value ?? [];
    final aInCart = cartItems.any((i) =>
        i.productId == productA.id && i.comboPartnerId == productB.id);
    final bInCart = cartItems.any((i) =>
        i.productId == productB.id && i.comboPartnerId == productA.id);
    final comboActive = aInCart && bInCart;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1040), Color(0xFF2D1B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C3CE1).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBC04),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt,
                                color: Color(0xFF1A1040), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'COMBO DEAL',
                              style: const TextStyle(
                                color: Color(0xFF1A1040),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (savingsPct > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Save $savingsPct%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    dealLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Product pair ─────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: _ProductTile(product: productA, comboPrice: aPriceCombo)),
                      // Plus icon divider
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 18),
                      ),
                      Expanded(child: _ProductTile(product: productB, comboPrice: bPriceCombo)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Price + CTA ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${regularTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${comboTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Color(0xFFFBBC04),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 26,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (savings > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      'save ₹${savings.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Color(0xFF4ADE80),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // CTA Button
                      GestureDetector(
                        onTap: comboActive || isAdding.value
                            ? null
                            : () async {
                                HapticFeedback.mediumImpact();
                                isAdding.value = true;
                                try {
                                  await ref
                                      .read(cartProvider.notifier)
                                      .addComboToCart(
                                        productA: productA,
                                        productB: productB,
                                      );
                                } finally {
                                  isAdding.value = false;
                                }
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: comboActive
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFFBBC04),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (comboActive
                                        ? const Color(0xFF4ADE80)
                                        : const Color(0xFFFBBC04))
                                    .withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: isAdding.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF1A1040),
                                  ),
                                )
                              : Text(
                                  comboActive ? '✓ Added' : 'Add Combo',
                                  style: const TextStyle(
                                    color: Color(0xFF1A1040),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final double comboPrice;

  const _ProductTile({required this.product, required this.comboPrice});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.primaryImage ?? '';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Product image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.image, color: Colors.white38),
                    )
                  : const Icon(Icons.image, color: Colors.white38),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          if (product.salePrice > comboPrice)
            Text(
              '₹${product.salePrice.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          Text(
            '₹${comboPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFFFBBC04),
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
