import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/theme/app_colors.dart';
import 'package:app/core/models/category_model.dart';
import 'providers/products_provider.dart';

// ─── CategoryModel visual metadata (icon + pastel colors per name) ─────────────────

class _CategoryMeta {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _CategoryMeta({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

const Map<String, _CategoryMeta> _kCategoryMeta = {
  'Fruits': _CategoryMeta(
    icon: Icons.local_dining,
    bgColor: Color(0xFFFFE5E5),
    iconColor: Color(0xFFD32F2F),
  ),
  'Vegetables': _CategoryMeta(
    icon: Icons.eco,
    bgColor: Color(0xFFE8F5E9),
    iconColor: Color(0xFF2E7D32),
  ),
  'Dairy': _CategoryMeta(
    icon: Icons.water_drop,
    bgColor: Color(0xFFE3F2FD),
    iconColor: Color(0xFF1976D2),
  ),
  'Snacks': _CategoryMeta(
    icon: Icons.fastfood,
    bgColor: Color(0xFFFFF3E0),
    iconColor: Color(0xFFF57C00),
  ),
  'Beverages': _CategoryMeta(
    icon: Icons.local_bar,
    bgColor: Color(0xFFF3E5F5),
    iconColor: Color(0xFF7B1FA2),
  ),
  'Bakery': _CategoryMeta(
    icon: Icons.bakery_dining,
    bgColor: Color(0xFFFFF8E1),
    iconColor: Color(0xFFFFA000),
  ),
  'Meat': _CategoryMeta(
    icon: Icons.restaurant,
    bgColor: Color(0xFFFFEBEE),
    iconColor: Color(0xFFC62828),
  ),
  'Frozen': _CategoryMeta(
    icon: Icons.ac_unit,
    bgColor: Color(0xFFE0F7FA),
    iconColor: Color(0xFF0097A7),
  ),
  'Organic': _CategoryMeta(
    icon: Icons.spa,
    bgColor: Color(0xFFF1F8E9),
    iconColor: Color(0xFF558B2F),
  ),
  'Grains': _CategoryMeta(
    icon: Icons.grain,
    bgColor: Color(0xFFFFF9C4),
    iconColor: Color(0xFFF9A825),
  ),
  'Seafood': _CategoryMeta(
    icon: Icons.set_meal,
    bgColor: Color(0xFFE1F5FE),
    iconColor: Color(0xFF0288D1),
  ),
  'Spices': _CategoryMeta(
    icon: Icons.local_fire_department,
    bgColor: Color(0xFFFFE0B2),
    iconColor: Color(0xFFE65100),
  ),
};

_CategoryMeta _metaFor(String name) {
  for (final key in _kCategoryMeta.keys) {
    if (name.toLowerCase().contains(key.toLowerCase())) {
      return _kCategoryMeta[key]!;
    }
  }
  // Default fallback
  return const _CategoryMeta(
    icon: Icons.category,
    bgColor: Color(0xFFEDE7F6),
    iconColor: Color(0xFF5416C9),
  );
}

// ─── Mock skeleton categories ─────────────────────────────────────────────────

List<CategoryModel> _mockCategories() => List.generate(
  8,
  (i) => CategoryModel(id: 'mock$i', name: 'Loading...', sortOrderModel: i),
);

// ─── Main Screen ──────────────────────────────────────────────────────────────

class BrowseCategoriesScreen extends HookConsumerWidget {
  const BrowseCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);
    final isLoading = categoriesState is AsyncLoading;
    final categories = categoriesState.value ?? _mockCategories();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F7FF),
        extendBodyBehindAppBar: true,
        appBar: _BrowseAppBar(),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(categoriesProvider),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top padding for AppBar
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 80,
                ),
              ),

              // Editorial header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                            'The Fresh Pantry',
                            style: GoogleFonts.manrope(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 6),
                      Text(
                        'Curated selections from our local organic partners.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                    ],
                  ),
                ),
              ),

              // CategoryModel grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: Skeletonizer.sliver(
                  enabled: isLoading,
                  child: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final cat = categories[index];
                      return _CategoryCard(
                        category: cat,
                        index: index,
                        isLoading: isLoading,
                      );
                    }, childCount: categories.length),
                  ),
                ),
              ),

              // Editorial feature card / hero banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: _HeroBannerCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top App Bar ──────────────────────────────────────────────────────────────

class _BrowseAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: Colors.white.withValues(alpha: 0.75),
          height: 64 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 8,
            right: 16,
          ),
          child: Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: () => context.pop(),
              ),
              // Title
              Expanded(
                child: Text(
                  'Browse Categories',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              // Search icon
              GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CategoryModel Card ────────────────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final int index;
  final bool isLoading;

  const _CategoryCard({
    required this.category,
    required this.index,
    required this.isLoading,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scaleController;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _scaleController.reverse();
  void _onTapUp(TapUpDetails _) => _scaleController.forward();
  void _onTapCancel() => _scaleController.forward();

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(widget.category.name);

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnim.value, child: child);
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(
            '/CategoryModel/${widget.category.id}?name=${Uri.encodeComponent(widget.category.name)}',
          );
        },
        child:
            Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A1B21).withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Content
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon circle
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: meta.bgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                meta.icon,
                                size: 36,
                                color: meta.iconColor,
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Label
                            Text(
                              widget.category.name,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Hover ring overlay (subtle)
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: null, // Handled by GestureDetector above
                            splashColor: AppColors.primary.withValues(
                              alpha: 0.06,
                            ),
                            highlightColor: AppColors.primary.withValues(
                              alpha: 0.03,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate(delay: Duration(milliseconds: 60 * widget.index))
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}

// ─── Hero Banner Card ─────────────────────────────────────────────────────────

class _HeroBannerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF5416C9), Color(0xFF6C3CE1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5416C9).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background produce image
          Positioned.fill(
            child: Image.network(
              'https://source.unsplash.com/featured/?shopping',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.35),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: const Color(0xFF6C3CE1)),
            ),
          ),
          // Gradient overlay at bottom for text legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF3B10A0).withValues(alpha: 0.85),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006B55),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Text(
                    'WEEKLY SPOTLIGHT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Title
                Text(
                  'Artisan Local Harvest',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                const Text(
                  'Discover limited-time seasonal picks from the Heart of the Valley farm cooperative.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // CTA button
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Shop Collection',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.1, end: 0);
  }
}
