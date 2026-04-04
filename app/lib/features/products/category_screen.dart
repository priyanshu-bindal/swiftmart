import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/theme/app_colors.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';

// --- State Management ---

typedef CategoryFilterArgs = ({String category, String filter});

final categoryProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, CategoryFilterArgs>((ref, args) async {
      final supabase = Supabase.instance.client;

      try {
        // 1. Get the category ID first to avoid complex inner join syntax issues
        final categoryResp = await supabase
            .from('categories')
            .select('id')
            .eq('name', args.category)
            .maybeSingle();

        if (categoryResp == null) return [];

        // 2. Fetch products for this category using reliable category_id filter
        var query = supabase
            .from('products')
            .select('*, categories(*)')
            .eq('is_active', true)
            .eq('category_id', categoryResp['id']);

        if (args.filter != 'All') {
          query = query.contains('tags', [args.filter.toLowerCase()]);
        }

        final response = await query;
        return (response as List)
            .map((json) => Product.fromJson(json))
            .toList();
      } catch (e) {
        // If anything fails, throw it clearly so Riverpod triggers the error state instead of hanging
        throw Exception('Failed to load products: \$e');
      }
    });

class CategoryScreen extends HookConsumerWidget {
  final String categoryName;

  const CategoryScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = useState('All');
    final productsAsync = ref.watch(
      categoryProductsProvider((
        category: categoryName,
        filter: selectedFilter.value,
      )),
    );

    // Example subcategories based on category
    final filterChips = ['All', 'Milk', 'Bread', 'Cheese', 'Eggs', 'Yogurt'];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(
          0xFFFBF8FF,
        ), // Using the surface color from the HTML
        extendBodyBehindAppBar: true,
        appBar: _CategoryAppBar(categoryName: categoryName),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.refresh(
            categoryProductsProvider((
              category: categoryName,
              filter: selectedFilter.value,
            )),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.top + 80,
                ),
              ), // Top padding for AppBar
              // Hero Banner Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: _HeroBanner(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Category Filters
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: filterChips.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final chip = filterChips[index];
                      final isSelected = chip == selectedFilter.value;
                      return GestureDetector(
                        onTap: () => selectedFilter.value = chip,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(
                                    0xFFE9E7EF,
                                  ), // surface-container-high
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            chip,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(
                                      0xFF494455,
                                    ), // on-surface-variant
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Product Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                sliver: productsAsync.when(
                  data: (products) {
                    if (products.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 48.0),
                          child: Center(
                            child: Text(
                              'No products found in this category.',
                              style: TextStyle(color: Color(0xFF494455)),
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.70, // Product card ratio
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (
                          context,
                          index,
                        ) => ProductCard(product: products[index])
                            .animate(delay: Duration(milliseconds: 50 * index))
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                        childCount: products.length,
                      ),
                    );
                  },
                  loading: () {
                    return Skeletonizer.sliver(
                      enabled: true,
                      child: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.70,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => ProductCard(
                            product: Product(
                              id: 'mock\$index',
                              name: 'Loading Item',
                              imagePath: '',
                              price: 0,
                            ),
                          ),
                          childCount: 4,
                        ),
                      ),
                    );
                  },
                  error: (error, stackTrace) => SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Oops, something went wrong:\\n\$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String categoryName;

  const _CategoryAppBar({required this.categoryName});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: Colors.white.withValues(alpha: 0.7),
          height: 64 + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 8,
            right: 16,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF6C3CE1)),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  categoryName,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1B21),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/search'),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.search, color: Color(0xFF6C3CE1), size: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFF4F2FA), Color(0xFFE2D6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * 0.5,
            child: Opacity(
              opacity: 0.6,
              child: Image.network(
                'https://source.unsplash.com/featured/?shopping',
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.overlay,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Daily Essentials',
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF5416C9), // Primary
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 200,
                  child: Text(
                    'Farm-to-table freshness delivered to your doorstep every morning.',
                    style: TextStyle(
                      color: Color(0xFF494455), // on-surface-variant
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}
