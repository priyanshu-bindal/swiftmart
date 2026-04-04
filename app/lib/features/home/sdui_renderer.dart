import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app/shared/widgets/app_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (component.type == 'banner_carousel')
      return const _BannerCarouselWidget();
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

  static Widget _buildCategoryRow() {
    final categories = [
      {
        'icon': Icons.apple,
        'label': 'Fruits',
        'bg': const Color(0xFFDCFCE7),
        'color': const Color(0xFF16A34A),
      },
      {
        'icon': Icons.egg,
        'label': 'Dairy',
        'bg': const Color(0xFFDBEAFE),
        'color': const Color(0xFF2563EB),
      },
      {
        'icon': Icons.cookie,
        'label': 'Snacks',
        'bg': const Color(0xFFFEF9C3),
        'color': const Color(0xFFCA8A04),
      },
      {
        'icon': Icons.local_bar,
        'label': 'Beverages',
        'bg': const Color(0xFFF3E8FF),
        'color': const Color(0xFF9333EA),
      },
    ];

    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Browse Categories',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/browse_categories'),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 24),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return GestureDetector(
                    onTap: () => context.push(
                      '/category',
                      extra: {'name': cat['label']},
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cat['bg'] as Color,
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: cat['color'] as Color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cat['label'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFlashDealsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixed,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => context.push('/flash-deals'),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: AppColors.tertiary,
                          size: 28,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Flash Deals',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.onTertiaryFixedVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.tertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.onTertiaryFixedVariant.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Text(
                      'ENDS IN: ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onTertiaryFixedVariant,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '02:45:12',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildDealCard(
                  'Strawberries 250g',
                  '\$3.50',
                  '\$5.80',
                  '-40%',
                  'https://source.unsplash.com/featured/?shopping',
                ),
                const SizedBox(width: 16),
                _buildDealCard(
                  'Bananas 1kg',
                  '\$1.20',
                  '\$1.60',
                  '-25%',
                  'https://source.unsplash.com/featured/?shopping',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDealCard(
    String title,
    String price,
    String oldPrice,
    String offText,
    String img,
  ) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 100,
                  width: 140,
                  child: AppNetworkImage(imageUrl: img, fit: BoxFit.cover, errorWidget: (context, url, error) => const Icon(Icons.error), placeholder: (context, url) => const Center(child: CircularProgressIndicator())),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    oldPrice,
                    style: const TextStyle(
                      color: AppColors.outline,
                      fontSize: 10,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Add',
                  style: TextStyle(
                    color: AppColors.onSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                offText,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onError,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildItemCard(
                  ref,
                  'Fortune Sunflower Oil',
                  '1 Litre',
                  r'$1.85',
                  r'$2.10',
                  'Best Seller',
                  AppColors.secondary,
                  'https://source.unsplash.com/featured/?shopping',
                  context: context,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildItemCard(
                  ref,
                  'Basmati Rice',
                  '5 kg',
                  r'$12.50',
                  r'$14.00',
                  'Low Stock',
                  AppColors.error,
                  'https://source.unsplash.com/featured/?shopping',
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildItemCard(
                  ref,
                  'Brown Eggs',
                  '12 Units',
                  r'$4.20',
                  null,
                  'OUT OF STOCK',
                  AppColors.onSurface,
                  'https://source.unsplash.com/featured/?shopping',
                  isOut: true,
                  context: context,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildItemCard(
                  ref,
                  'Moong Dal',
                  '1 kg',
                  r'$3.40',
                  r'$3.80',
                  null,
                  null,
                  'https://source.unsplash.com/featured/?shopping',
                  context: context,
                ),
              ),
            ],
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
    BuildContext? context,
  }) {
    final productId = title.toLowerCase().replaceAll(' ', '-');
    return GestureDetector(
      onTap: context != null ? () => context.push('/product/$productId') : null,
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
