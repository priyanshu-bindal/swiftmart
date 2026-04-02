import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? topBadge;
    Color? badgeColor;
    if (product.name.toLowerCase().contains('mango')) {
      topBadge = 'BEST SELLER';
      badgeColor = const Color(0xFF00966D);
    } else if (product.name.toLowerCase().contains('coke') || product.name.toLowerCase().contains('cola')) {
      topBadge = 'LOW STOCK';
      badgeColor = const Color(0xFFA52A2A);
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 110,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9F7FB)
                    ),
                    child: Hero(
                      tag: 'product-${product.id}',
                      child: CachedNetworkImage(
                        imageUrl: product.imagePath,
                        fit: BoxFit.cover,
                        memCacheWidth: 220,
                        memCacheHeight: 220,
                        fadeInDuration: const Duration(milliseconds: 200),
                        fadeOutDuration: const Duration(milliseconds: 200),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, height: 1.3, color: Color(0xFF1E1E1E)),
                          ),
                          const SizedBox(height: 4),
                          Text(product.unit ?? '', style: const TextStyle(color: Color(0xFF7A869A), fontSize: 9, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${(product.discountedPrice ?? product.price).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF6C3CE1)),
                                  ),
                                  if (product.discountedPrice != null && product.discountedPrice! > 0)
                                    Text(
                                      '\$${product.price.toStringAsFixed(2)}',
                                      style: const TextStyle(color: Color(0xFF9E9CA7), fontSize: 9, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Consumer(
                                builder: (context, ref, _) {
                                  return InkWell(
                                    onTap: () {
                                      ref.read(cartProvider.notifier).addProduct(product);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4FF4C5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.plus, color: Color(0xFF1E1E1E), size: 18),
                                    ),
                                  ).animate().scaleXY(begin: 1.0, end: 1.15, duration: 150.ms, curve: Curves.easeOutBack);
                                }
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (topBadge != null)
                Positioned(
                  top: 0,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor, 
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8))
                    ),
                    child: Text(topBadge, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
