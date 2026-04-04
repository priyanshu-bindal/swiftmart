import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app/shared/widgets/app_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../features/cart/providers/cart_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/remote_config_service.dart';
import 'models/sdui_models.dart';
import 'widgets/unknown_component_widget.dart';
import 'widgets/animated_search_bar.dart';

// Provider to fetch banners prioritising Supabase, falling back to Remote Config
final bannerImagesProvider = FutureProvider<List<String>>((ref) async {
  final supabase = Supabase.instance.client;
  var urls = <String>[];

  try {
    final response = await supabase
        .from('banners')
        .select('image_url')
        .eq('is_active', true);
    debugPrint('Supabase response: $response');
    urls = (response as List).map((row) => row['image_url'] as String).toList();
  } catch (e) {
    debugPrint('Supabase banners error: ${e.toString()}');
    urls = [];
  }

  if (urls.isEmpty) {
    // Fallback to remote config if table empty or query failed
    final rcConfig = ref.read(remoteConfigServiceProvider);
    final b1 = rcConfig.getString('banner_1_url');
    final b2 = rcConfig.getString('banner_2_url');
    if (b1.isNotEmpty) urls.add(b1);
    if (b2.isNotEmpty) urls.add(b2);
  }

  // If remote config is ALSO empty, use a hardcoded default just so UI doesn't break
  if (urls.isEmpty) {
    urls.add(
      'https://source.unsplash.com/featured/?shopping',
    );
  }

  return urls;
});

class SduiRenderer {
  static Widget render(SduiComponent component) {
    if (component.type == 'search_bar') return _buildSearchBar();
    if (component.type == 'banner_carousel') {
      return const _BannerCarouselWidget();
    }
    if (component.type == 'category_row') return _buildCategoryRow();
    if (component.type == 'flash_deals_row') return _buildFlashDealsRow();
    if (component.type == 'value_combos') return _buildValueCombos();
    if (component.type == 'coupon_strip') return _buildCouponStrip();
    if (component.type == 'product_grid') return const _DailyEssentialsWidget();

    return UnknownComponentWidget(componentType: component.type);
  }

  static Widget _buildSearchBar() {
    return const AnimatedSearchBar();
  }

  static Widget _buildCategoryRow() => const _HomeCategoryRowWidget();

  static Widget _buildFlashDealsRow() => const _HomeFlashDealsWidget();



  static Widget _buildValueCombos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Value Combos',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                    border: Border.all(
                      color: AppColors.secondaryContainer.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'SAVE 15%',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Breakfast Bundle',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.onSurface,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Milk + Bread + Eggs',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Text(
                                  'Add to Cart ',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.primary,
                                  size: 14,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: AppNetworkImage(
                          imageUrl:
                              'https://source.unsplash.com/featured/?shopping',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    border: Border.all(
                      color: AppColors.primaryFixedDim.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'SAVE 20%',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Salad Trio',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.onSurface,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Lettuce + Tomato + Cucumber',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Text(
                                  'Add to Cart ',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.primary,
                                  size: 14,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: AppNetworkImage(
                          imageUrl:
                              'https://source.unsplash.com/featured/?shopping',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildCouponStrip() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => context.push('/coupons'),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.3),
              style: BorderStyle.none,
            ), // Wait, flutter border dashed needs a custom painter, we'll use solid for now
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.confirmation_number,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Apply Coupon & Save ₹50',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'ON ORDERS ABOVE ₹499',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: AppColors.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Text(
                'APPLY',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyEssentialsWidget extends HookConsumerWidget {
  const _DailyEssentialsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(_dailyEssentialsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Essentials',
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          productsAsync.when(
            data: (products) {
              if (products.isEmpty) return const SizedBox();
              final rows = <Widget>[];
              for (int i = 0; i < products.length; i += 2) {
                final left = products[i];
                final right = i + 1 < products.length ? products[i + 1] : null;
                rows.add(
                  Row(
                    children: [
                      Expanded(
                        child: _buildItemCard(
                          ref,
                          left.name,
                          left.unit ?? '',
                          '₹${left.price.toStringAsFixed(0)}',
                          left.mrp > left.price ? '₹${left.mrp.toStringAsFixed(0)}' : null,
                          left.isBestSeller ? 'Best Seller' : (left.stockCount == 0 ? 'OUT OF STOCK' : null),
                          left.isBestSeller ? AppColors.secondary : (left.stockCount == 0 ? AppColors.onSurface : null),
                          left.imagePath,
                          isOut: left.stockCount == 0,
                          productId: left.id,
                          context: context,
                        ),
                      ),
                      if (right != null) ...[  
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildItemCard(
                            ref,
                            right.name,
                            right.unit ?? '',
                            '₹${right.price.toStringAsFixed(0)}',
                            right.mrp > right.price ? '₹${right.mrp.toStringAsFixed(0)}' : null,
                            right.isBestSeller ? 'Best Seller' : (right.stockCount == 0 ? 'OUT OF STOCK' : null),
                            right.isBestSeller ? AppColors.secondary : (right.stockCount == 0 ? AppColors.onSurface : null),
                            right.imagePath,
                            isOut: right.stockCount == 0,
                            productId: right.id,
                            context: context,
                          ),
                        ),
                      ] else
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                );
                if (i + 2 < products.length) rows.add(const SizedBox(height: 16));
              }
              return Column(children: rows);
            },
            loading: () => Skeletonizer(
              enabled: true,
              child: Column(
                children: List.generate(
                  2,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            error: (e, _) => Text(
              'Could not load products',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    WidgetRef ref,
    String title,
    String subtitle,
    String price,
    String? oldPrice,
    String? topBadge,
    Color? badgeColor,
    String imgUrl, {
    bool isOut = false,
    String? productId,
    BuildContext? context,
  }) {
    return GestureDetector(
      onTap: (context != null && productId != null)
          ? () => context.push('/product/$productId')
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isOut
                      ? ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                          child: AppNetworkImage(
                            imageUrl: imgUrl,
                            fit: BoxFit.cover,
                          ),
                        )
                      : AppNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover, errorWidget: (context, url, error) => const Icon(Icons.error), placeholder: (context, url) => const Center(child: CircularProgressIndicator())),
                ),
                if (topBadge != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        topBadge,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.outline),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    if (oldPrice != null)
                      Text(
                        oldPrice,
                        style: const TextStyle(
                          color: AppColors.outline,
                          fontSize: 9,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    if (isOut) return;
                    // These are display-only cards without real Supabase product IDs.
                    // Navigate to search to find and add real products.
                    if (context != null) context.push('/search');
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isOut
                          ? AppColors.surfaceContainerHigh
                          : AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isOut ? Icons.block : Icons.add,
                      color: isOut
                          ? AppColors.outline
                          : AppColors.onSecondaryContainer,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerCarouselWidget extends HookConsumerWidget {
  const _BannerCarouselWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersState = ref.watch(bannerImagesProvider);

    return bannersState.when(
      data: (urls) {
        if (urls.isEmpty) return const SizedBox();

        // Standardizing simple display of the very first banner for the carousel placeholder
        // and optionally wrapping in a PageView if multiple
        final url = urls.first;

        return Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryContainer],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 180,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                  child: AppNetworkImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (context, url, error) => const Icon(Icons.error), placeholder: (context, url) => const Center(child: CircularProgressIndicator())),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'FLASH SALE',
                        style: TextStyle(
                          color: AppColors.onSecondaryContainer,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Flat 40% OFF\non Organic Greens',
                      style: GoogleFonts.manrope(
                        color: AppColors.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => context.push('/flash-deals'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Shop Now',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
      error: (_, _) => const SizedBox(),
    );
  }
}

// ── Real Supabase providers ────────────────────────────────────────────────────

/// Fetches up to 8 products tagged 'daily_essential', falls back to first 8.
final _dailyEssentialsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final taggedData = await supabase
        .from('products')
        .select('*, categories(*)')
        .eq('is_active', true)
        .contains('tags', ['daily_essential'])
        .limit(8);
    final tagged = (taggedData as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    if (tagged.isNotEmpty) return tagged;
    final fallbackData = await supabase
        .from('products')
        .select('*, categories(*)')
        .eq('is_active', true)
        .limit(8);
    return (fallbackData as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('_dailyEssentialsProvider error: $e\n$st');
    return [];
  }
});

final _homeCategoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  try {
    final data = await Supabase.instance.client
        .from('categories')
        .select()
        .order('sort_order', ascending: true);
    return (data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('_homeCategoriesProvider error: $e\n$st');
    return [];
  }
});

class _HomeCategoryRowWidget extends HookConsumerWidget {
  const _HomeCategoryRowWidget();

  static const _kMeta = <String, Map<String, dynamic>>{
    'fruits':     {'icon': Icons.apple,              'bg': Color(0xFFDCFCE7), 'color': Color(0xFF16A34A)},
    'vegetables': {'icon': Icons.eco,                'bg': Color(0xFFE8F5E9), 'color': Color(0xFF2E7D32)},
    'dairy':      {'icon': Icons.water_drop,         'bg': Color(0xFFDBEAFE), 'color': Color(0xFF2563EB)},
    'snacks':     {'icon': Icons.cookie,             'bg': Color(0xFFFEF9C3), 'color': Color(0xFFCA8A04)},
    'beverages':  {'icon': Icons.local_bar,          'bg': Color(0xFFF3E8FF), 'color': Color(0xFF9333EA)},
    'bakery':     {'icon': Icons.bakery_dining,      'bg': Color(0xFFFFF8E1), 'color': Color(0xFFFFA000)},
    'meat':       {'icon': Icons.restaurant,         'bg': Color(0xFFFFEBEE), 'color': Color(0xFFC62828)},
    'frozen':     {'icon': Icons.ac_unit,            'bg': Color(0xFFE0F7FA), 'color': Color(0xFF0097A7)},
    'grains':     {'icon': Icons.grain,              'bg': Color(0xFFFFF9C4), 'color': Color(0xFFF9A825)},
    'spices':     {'icon': Icons.local_fire_department, 'bg': Color(0xFFFFE0B2), 'color': Color(0xFFE65100)},
  };

  Map<String, dynamic> _metaFor(String name) {
    final lower = name.toLowerCase();
    for (final key in _kMeta.keys) {
      if (lower.contains(key)) return _kMeta[key]!;
    }
    return {'icon': Icons.category, 'bg': const Color(0xFFEDE7F6), 'color': const Color(0xFF5416C9)};
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(_homeCategoriesProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Browse Categories',
                style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onSurface)),
              GestureDetector(
                onTap: () => context.push('/browse_categories'),
                child: const Text('View All',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 96,
            child: categoriesAsync.when(
              data: (cats) => ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: cats.length,
                separatorBuilder: (_, unused) => const SizedBox(width: 20),
                itemBuilder: (context, i) {
                  final cat = cats[i];
                  final meta = _metaFor(cat.name);
                  return GestureDetector(
                    onTap: () => context.push('/category/${cat.id}?name=${Uri.encodeComponent(cat.name)}'),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: meta['bg'] as Color,
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Icon(meta['icon'] as IconData, color: meta['color'] as Color, size: 28),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 64,
                          child: Text(cat.name,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  );
                },
              ),
              loading: () => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                separatorBuilder: (_, unused) => const SizedBox(width: 20),
                itemBuilder: (_, unused2) => Column(children: [
                  Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200)),
                  const SizedBox(height: 8),
                  Container(width: 48, height: 10, color: Colors.grey.shade200),
                ]),
              ),
              error: (_, unused) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}

final _homeFlashDealsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final now = DateTime.now().toUtc().toIso8601String();
    final data = await Supabase.instance.client
        .from('flash_deals')
        .select('*, products(*)')
        .eq('is_active', true)
        .lte('start_time', now)
        .gte('end_time', now)
        .limit(6);
    return List<Map<String, dynamic>>.from(data as List);
  } catch (e, st) {
    debugPrint('_homeFlashDealsProvider error: $e\n$st');
    return [];
  }
});

class _HomeFlashDealsWidget extends HookConsumerWidget {
  const _HomeFlashDealsWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(_homeFlashDealsProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.tertiaryFixed, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.push('/flash-deals'),
                child: Row(children: [
                  const Icon(Icons.bolt, color: AppColors.tertiary, size: 26),
                  const SizedBox(width: 4),
                  Text('Flash Deals', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.onTertiaryFixedVariant)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.tertiary),
                ]),
              ),
              GestureDetector(
                onTap: () => context.push('/flash-deals'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.onTertiaryFixedVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('VIEW ALL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.onTertiaryFixedVariant, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          dealsAsync.when(
            data: (deals) {
              if (deals.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No active flash deals', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                );
              }
              return SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: deals.length,
                  separatorBuilder: (_, unused) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final deal = deals[i];
                    final rawProduct = deal['products'];
                    Product? product;
                    if (rawProduct is Map<String, dynamic>) {
                      product = Product.fromJson(rawProduct);
                    } else if (rawProduct is List && rawProduct.isNotEmpty) {
                      product = Product.fromJson(rawProduct.first as Map<String, dynamic>);
                    }
                    if (product == null) return const SizedBox();
                    final discountPct = deal['discount_pct'] as int? ?? product.discountPercent;
                    return GestureDetector(
                      onTap: () => context.push('/product/${product!.id}'),
                      child: Container(
                        width: 150,
                        decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.all(10),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    height: 96, width: double.infinity,
                                    child: product.imagePath.isNotEmpty
                                        ? AppNetworkImage(imageUrl: product.imagePath, fit: BoxFit.cover)
                                        : Container(color: Colors.grey.shade100, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Text('₹${product.price.toStringAsFixed(0)}',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 14)),
                                  if (product.mrp > product.price) ...[
                                    const SizedBox(width: 6),
                                    Text('₹${product.mrp.toStringAsFixed(0)}',
                                      style: const TextStyle(color: AppColors.outline, fontSize: 10, decoration: TextDecoration.lineThrough)),
                                  ],
                                ]),
                                const Spacer(),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => ref.read(cartProvider.notifier).addToCart(product!.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                      foregroundColor: AppColors.onSecondary,
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            if (discountPct > 0)
                              Positioned(
                                top: 4, right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                                  child: Text('-$discountPct%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.onError)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, unused) => const SizedBox(width: 12),
                itemBuilder: (_, unused2) => Container(width: 150, height: 220,
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16))),
              ),
            ),
            error: (_, unused) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}
