import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app/shared/widgets/app_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../cart/providers/cart_provider.dart';
import '../../repositories/product_repository.dart';
import 'package:app/core/models/product_model.dart';
import '../../shared/widgets/cart_toast_bar.dart';
import '../../shared/providers/cart_toast_provider.dart';

// No dummy fallback - always load from Supabase

final productDetailProvider = FutureProvider.family<ProductModel?, String>((
  ref,
  id,
) {
  return ref.read(productRepositoryProvider).fetchProductById(id);
});

class ProductDetailScreen extends HookConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stage the local count purely for UI before committing to Cart
    final localCount = useState(1);

    // Fetch right ProductModel from repo
    final productAsync = ref.watch(productDetailProvider(productId));

    // Show loading or error before the ProductModel is ready
    if (productAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (productAsync.hasError || productAsync.value == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ProductModel')),
        body: Center(
          child: Text(
            productAsync.hasError
                ? 'Failed to load product:\n${productAsync.error}'
                : 'ProductModel not found',
          ),
        ),
      );
    }

    final product = productAsync.value!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      extendBody: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.7),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.primaryContainer,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        'SwiftMart',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.favorite,
                          color: AppColors.outline,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: AppColors.outline),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 80,
                bottom: 120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 350,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Hero(
                            tag: 'ProductModel-${product.id}',
                            child: (product.primaryImage?.isEmpty ?? true)
                                ? Container(
                                    color: AppColors.surfaceContainerLow,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: AppColors.outline,
                                        size: 48,
                                      ),
                                    ),
                                  )
                                : AppNetworkImage(
                                    imageUrl: product.primaryImage!,
                                    fit: BoxFit.cover,
                                    fadeInDuration: const Duration(
                                      milliseconds: 200,
                                    ),
                                    memCacheWidth: 800,
                                    placeholder: (context, url) => Container(
                                      color: AppColors.surfaceContainerLow,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: AppColors.surfaceContainerLow,
                                          child: const Center(
                                            child: Icon(
                                              Icons.error,
                                              color: AppColors.outline,
                                              size: 48,
                                            ),
                                          ),
                                        ),
                                  ),
                          ),
                        ),
                        if (product.tags.contains('organic'))
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryFixed,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'ORGANIC',
                                style: TextStyle(
                                  color: AppColors.onSecondaryFixed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ProductModel Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.brand != null)
                          Text(
                            product.brand!.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          product.name,
                          style: GoogleFonts.manrope(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                Icon(
                                  Icons.star_half,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '(128 reviews)',
                              style: TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${product.salePrice.toInt()}',
                              style: GoogleFonts.manrope(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (product.mrp > product.salePrice)
                              Text(
                                '₹${product.mrp.toInt()}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            const SizedBox(width: 12),
                            if (product.mrp > product.salePrice)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '-${product.discountPercent}% OFF',
                                  style: const TextStyle(
                                    color: AppColors.onErrorContainer,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        if (product.discountPercent > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer.withValues(
                                  alpha: 0.3,
                                ),
                                border: Border.all(
                                  color: AppColors.secondaryContainer
                                      .withValues(alpha: 0.5),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.account_balance_wallet,
                                    color: AppColors.secondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Get ₹${product.discountPercent} discountPercent',
                                    style: const TextStyle(
                                      color: AppColors.onSecondaryContainer,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quantity & Cart Action
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  if (localCount.value > 1) localCount.value--;
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.remove,
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                              ),
                              Container(
                                width: 40,
                                alignment: Alignment.center,
                                child: Text(
                                  '${localCount.value}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => localCount.value++,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              try {
                                HapticFeedback.lightImpact();
                                await ref
                                    .read(cartProvider.notifier)
                                    .addToCart(
                                      product.id,
                                      quantity: localCount.value,
                                    );
                                if (context.mounted) {
                                  localCount.value = 1;
                                  ref.read(cartToastProvider.notifier).show(
                                    productName: product.name,
                                    productImage: product.primaryImage,
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to add: $e'),
                                      backgroundColor: AppColors.error,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add to Cart',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Combo Offers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Frequently Bought Together',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Text(
                          'Add All',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      children: [
                        _ComboBundleCard(
                          title: 'Morning Essentials Bundle',
                          price: '₹185',
                          saving: 'Save 15%',
                          images: const [
                            'https://source.unsplash.com/featured/?shopping',
                            'https://source.unsplash.com/featured/?shopping',
                            'https://source.unsplash.com/featured/?shopping',
                          ],
                        ),
                        const SizedBox(width: 16),
                        _ComboBundleCard(
                          title: "Dessert Maker's Pack",
                          price: '₹95',
                          saving: 'Save 10%',
                          images: const [
                            'https://source.unsplash.com/featured/?shopping',
                            'https://source.unsplash.com/featured/?shopping',
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Accordions (Details)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: const Text(
                              'Description',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            iconColor: AppColors.primary,
                            collapsedIconColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceContainerLow,
                            collapsedBackgroundColor:
                                AppColors.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            initiallyExpanded: true,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Text(
                                  product.description ?? '',
                                  style: const TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: const Text(
                              'Nutritional Info',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            iconColor: AppColors.primary,
                            collapsedIconColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceContainerLow,
                            collapsedBackgroundColor:
                                AppColors.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            children: const [],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: const Text(
                              'Storage & Care',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            iconColor: AppColors.primary,
                            collapsedIconColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceContainerLow,
                            collapsedBackgroundColor:
                                AppColors.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            children: const [],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Recommendations
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'You may also like',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    height: 210,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      children: const [
                        _MiniProductCard(
                          name: 'Golden Pineapple',
                          price: '₹80',
                          imgUrl:
                              'https://source.unsplash.com/featured/?shopping',
                        ),
                        SizedBox(width: 16),
                        _MiniProductCard(
                          name: 'Wild Blueberries',
                          price: '₹190',
                          imgUrl:
                              'https://source.unsplash.com/featured/?shopping',
                        ),
                        SizedBox(width: 16),
                        _MiniProductCard(
                          name: 'Fuji Apples',
                          price: '₹120',
                          imgUrl:
                              'https://source.unsplash.com/featured/?shopping',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
          // ── Floating cart toast overlay ───────────────────────────────
          const CartToastBar(bottomOffset: 24),
        ],
      ),
    );
  }
}

class _ComboBundleCard extends StatelessWidget {
  final String title;
  final String price;
  final String saving;
  final List<String> images;

  const _ComboBundleCard({
    required this.title,
    required this.price,
    required this.saving,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: images
                    .map(
                      (img) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: AppNetworkImage(
                              imageUrl: img,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        saving,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    price,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String imgUrl;

  const _MiniProductCard({
    required this.name,
    required this.price,
    required this.imgUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            height: 130,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppNetworkImage(
                imageUrl: imgUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                memCacheWidth: 300,
                placeholder: (_, _) =>
                    Container(color: AppColors.surfaceContainerLow),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              price,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
