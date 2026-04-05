import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'app_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/theme/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../features/cart/providers/cart_provider.dart';
import '../providers/cart_toast_provider.dart';

class ProductCard extends HookConsumerWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider).asData?.value ?? [];
    final cartItem = cartItems
        .where((i) => i.productId == product.id)
        .firstOrNull;
    final quantity = cartItem?.quantity ?? 0;

    return GestureDetector(
      onTap: () => context.push('/ProductModel/${product.id}'),
      child: Container(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Image Container
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: product.primaryImage == null
                        ? const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppColors.outline,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: AppNetworkImage(
                              imageUrl: product.primaryImage!,
                              fit: BoxFit.contain, // Contain so the whole product is visible within padding
                              width: double.infinity,
                              placeholder: (context, url) => const Skeletonizer(
                                enabled: true,
                                child: Bone.square(size: 400),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(
                                  Icons.error,
                                  color: AppColors.outline,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                
                // Discount Badge (Top Left)
                if (product.discountPercent > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        '${product.discountPercent}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),

                // Heart Icon (Top Right)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    Icons.favorite_border,
                    color: Color(0xFF9E9CA7),
                    size: 20,
                  ),
                ),

                // Low / Out of stock label (below discount)
                if (product.stockQty <= 5)
                  Positioned(
                    top: product.discountPercent > 0 ? 28 : 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: product.stockQty == 0 ? Colors.grey : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.stockQty == 0 ? 'Out of Stock' : 'Low Stock',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // ADD Button (Bottom Right) Overlapping container edge
                Positioned(
                  bottom: -14,
                  right: 8,
                  child: _buildAddButton(ref, quantity, product.stockQty == 0),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 18), // Space to accommodate the overlapping button
          
          // Details Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Veg Icon & Unit
                Row(
                  children: [
                    _buildVegIcon(),
                    const SizedBox(width: 6),
                    Text(
                      product.unit ?? '1 unit',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A454E), // Dark grey
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Title
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1E1E1E),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                
                // Mock Ratings
                Row(
                  children: [
                    for (int i = 0; i < 4; i++)
                      const Icon(Icons.star, color: Color(0xFFF2C236), size: 10),
                    const Icon(Icons.star_half, color: Color(0xFFF2C236), size: 10),
                    const SizedBox(width: 4),
                    const Text(
                      '(50,611)',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF7A869A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Delivery Time
                const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: Color(0xFF2E7D32), size: 10),
                    SizedBox(width: 4),
                    Text(
                      '8 MINS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Price
                Row(
                  children: [
                    Text(
                      '₹${product.salePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    if (product.mrp > product.salePrice) ...[
                      const SizedBox(width: 6),
                      Text(
                        'MRP ₹${product.mrp.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                          color: Color(0xFF9E9CA7),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 8),
                
                // "See more like this" Bottom Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF7F0), // Pale green
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'See more like this',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.play_arrow,
                        color: Color(0xFF2E7D32),
                        size: 10,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildVegIcon() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2E7D32), width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF2E7D32),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(WidgetRef ref, int quantity, bool isOutOfStock) {
    if (isOutOfStock) {
      return Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCDCDC)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'SOLD OUT',
          style: TextStyle(
            color: Color(0xFF7A869A),
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      );
    }

    if (quantity == 0) {
      return InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          ref.read(cartProvider.notifier).addToCart(product.id);
          ref.read(cartToastProvider.notifier).show(
            productName: product.name,
            productImage: product.primaryImage,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF2E7D32), width: 1),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'ADD',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // Quantity > 0
    final cartItems = ref.read(cartProvider).asData?.value ?? [];
    final cartItem = cartItems.where((i) => i.productId == product.id).firstOrNull;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (cartItem != null) {
                ref.read(cartProvider.notifier).decrementItem(cartItem);
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(Icons.remove, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$quantity',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(cartProvider.notifier).addToCart(product.id);
              ref.read(cartToastProvider.notifier).show(
                productName: product.name,
                productImage: product.primaryImage,
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
