import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../shared/widgets/app_network_image.dart';
import '../orders/widgets/active_order_banner.dart';
import '../../shared/providers/nav_visibility_provider.dart';
import '../deals/providers/flash_deals_provider.dart';
import '../deals/widgets/deal_countdown_timer.dart';
import '../deals/widgets/flash_deal_product_card.dart';

// Provider to fetch banners
final bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  return await supabase.from('banners').select().eq('is_active', true);
});

// Provides lists of maps representing categories with images
final homeCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  // Get all categories ordered by sort_order
  final categoriesResponse = await supabase.from('categories').select().order('sort_order', ascending: true);
  
  // Fetch products to extract category images
  final productsResponse = await supabase.from('products').select('image_url, category_id, category');

  final List<Map<String, dynamic>> res = [];
  for (var cat in categoriesResponse) {
    // Find products matching either category_id or string category
    var matchingProds = productsResponse.where((p) {
      if (p['category_id'] == cat['id']) return true;
      if (p['category'] != null && 
          p['category'].toString().toLowerCase() == cat['name'].toString().toLowerCase()) {
        return true;
      }
      return false;
    }).toList();
    
    var images = matchingProds
        .map((p) => p['image_url']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .take(4)
        .toList();
    
    res.add({
      'id': cat['id'],
      'name': cat['name'],
      'images': images,
      'totalCount': matchingProds.length,
    });
  }
  return res;
});

final groupedProductsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  // Get all categories ordered by sort_order
  final categoriesResponse = await supabase.from('categories').select().order('sort_order', ascending: true);
  // Get active products
  final productsResponse = await supabase.from('products').select().eq('is_active', true);

  final List<Map<String, dynamic>> res = [];
  for (var cat in categoriesResponse) {
    // Find products matching the category
    var matchingProds = productsResponse.where((p) {
      if (p['category_id'] == cat['id']) return true;
      if (p['category'] != null && 
          p['category'].toString().toLowerCase() == cat['name'].toString().toLowerCase()) {
        return true;
      }
      return false;
    }).toList();
    
    // Only add categories that have products, take up to 6 products
    if (matchingProds.isNotEmpty) {
      res.add({
        'category': cat,
        'products': matchingProds.take(6).toList(),
      });
    }
  }
  return res;
});

enum HomeItemType { banner, category }

class HomeItem {
  final HomeItemType type;
  final Map<String, dynamic>? banner;
  final Map<String, dynamic>? categoryGroup;

  HomeItem.banner(this.banner) : type = HomeItemType.banner, categoryGroup = null;
  HomeItem.category(this.categoryGroup) : type = HomeItemType.category, banner = null;
}

class HomeScreen extends StatefulHookConsumerWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Aggressively pre-cache category images as soon as they load
    ref.listen(homeCategoriesProvider, (prev, next) {
      if (next is AsyncData) {
        for (var cat in next.value!) {
          for (var img in cat['images']) {
            if (img.toString().isNotEmpty) precacheImage(CachedNetworkImageProvider(img, maxHeight: 400), context);
          }
        }
      }
    });

    // Aggressively pre-cache product images
    ref.listen(groupedProductsProvider, (prev, next) {
      if (next is AsyncData) {
        for (var group in next.value!) {
          for (var p in group['products']) {
            final url = p['image_url']?.toString() ?? '';
            if (url.isNotEmpty) precacheImage(CachedNetworkImageProvider(url, maxHeight: 400), context);
          }
        }
      }
    });

    // Aggressively pre-cache banners
    ref.listen(bannersProvider, (prev, next) {
      if (next is AsyncData) {
        for (var b in next.value!) {
          final url = b['image_url']?.toString() ?? '';
          if (url.isNotEmpty) precacheImage(CachedNetworkImageProvider(url, maxHeight: 800), context);
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.forward) {
              ref.read(navVisibilityProvider.notifier).show();
            } else if (notification.direction == ScrollDirection.reverse) {
              ref.read(navVisibilityProvider.notifier).hide();
            }
            return false;
          },
          child: RefreshIndicator(
            color: const Color(0xFF006B5C),
            onRefresh: () async {
              ref.invalidate(homeCategoriesProvider);
              ref.invalidate(groupedProductsProvider);
              ref.invalidate(bannersProvider);
              ref.invalidate(flashDealsFutureProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(context),
                  const SizedBox(height: 8),
                  const ActiveOrderBanner(),
                  const SizedBox(height: 4),
                  
                  _buildSearchBar(context),
                  const SizedBox(height: 16),
                  _buildHeroBanner(),
                  const SizedBox(height: 24),
                  _buildFlashDealsSection(ref),
                  const SizedBox(height: 24),
                  _buildDailySavings(),
                  const SizedBox(height: 24),
                  _buildShopByCategory(ref),
                  const SizedBox(height: 32),
                  _buildDynamicFeed(ref),
                  
                  const SizedBox(height: 120), // Spacing for bottom nav
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'DELIVERY IN 8 MINUTES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF006B5C),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.bolt, color: Color(0xFF006B5C), size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'User address profile...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1C1D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF4A454E)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF006B5C).withValues(alpha: 0.2), width: 2),
                image: const DecorationImage(
                  image: CachedNetworkImageProvider('https://lh3.googleusercontent.com/aida-public/AB6AXuA199lxjUYB1dc1Q45OLCjH3X_0-WRUfpNhLMKb1R8owyAEAgIJkYc_quYiJJpds4-xeebvNGtYH-G132SHjvXrbJMMyfkpemsCpUUGQlruHhf9OtwgFuemi8zSMZgOYMmSLgylyj_d5WVSOKPb_MVkkplX28ftssCtQmDvFViPkncWvzNl1UKweA6U9AOHvDXku39H-fTNnbMsd_WoMdUDv7YjZl2BJxFN0-illwsVt5OHO3Q3hXFyipC63mOdPeutFmYWCmyewqoa'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => context.push('/search'),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
          color: const Color(0xFFF3F3F5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF4A454E)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Search 'milk'",
                style: TextStyle(
                  color: Color(0xFF4A454E),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.mic, color: Color(0xFF006B5C)),
          ],
        ),
      ),
    ), // This closes GestureDetector
  ); // This closes Padding
}

  Widget _buildHeroBanner() {
    final bannersAsync = ref.watch(bannersProvider);
    return bannersAsync.when(
      data: (allBanners) {
        // Filter banners marked for the 'hero' position (top of page)
        final heroBanners = allBanners
            .where((b) =>
                b['placement_after']?.toString().toLowerCase() == 'hero')
            .toList();

        // If admin has hero banners, show a live carousel
        if (heroBanners.isNotEmpty) {
          return _DynamicHeroCarousel(banners: heroBanners, onTap: _handleBannerTap);
        }

        // Fallback: static hero
        return _buildStaticHero();
      },
      loading: () => _buildStaticHero(),
      error: (_, __) => _buildStaticHero(),
    );
  }

  Widget _buildStaticHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB870), Color(0xFFFFDCBE), Color(0xFFFFB870)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        ),
        child: Stack(
          children: [
            // Decorative right side image
            Positioned(
              right: -20,
              bottom: 0,
              width: 220,
              height: 220,
              child: AppNetworkImage(
                imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC8oFOM_oJjC9Mns4dTa2OHbmOIOwH-CFsRb-EER7nXmpzhaJQfsil8n2kePN0G0QSuO_uoa8xqAc50kT1xvyHUtYsw0V28ptz4lVSP9sg0pJyrensZqeLC6pnYRViwsI58z4V7wiWpCT7TBF3A559b9iDD1r8_9LOPJvgH8vJZVxLiBI-X0EJeXDW7nzJ0fZxB9epgvS-ciKnuq1WuztU5cTPbbM2eW-oMc_kb9UIuXdgo452zDBEA-ws-LrrztmPnwVBOe3faAOzP',
                fit: BoxFit.contain,
                colorBlendMode: BlendMode.multiply,
              ),
            ),
            // Text Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "WELCOME",
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF180331),
                      fontWeight: FontWeight.w800,
                      fontSize: 34,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SizedBox(
                    width: 140,
                    child: Text(
                      "Order now and enjoy great offers",
                      style: TextStyle(
                        color: Color(0xFF693C00),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF180331),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: const Color(0xFF180331).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text("Shop Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFlashDealsSection(WidgetRef ref) {
    final state = ref.watch(flashDealsFutureProvider);
    
    return state.when(
      data: (deals) {
        if (deals.isEmpty) return const SizedBox.shrink();
        // Since there might be multiple live deals, 
        // we'll just show the first active one, or we could list all of them.
        final deal = deals.first; 
        final dealColor = _parseColor(deal['badge_color']?.toString());
        final productsList = deal['flash_deal_products'] as List? ?? [];
        final validProducts = productsList.where((p) => p['products'] != null).toList();

        if (validProducts.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.amber, size: 28),
                      const SizedBox(width: 8),
                      Text('Flash Deals', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF180331))),
                    ],
                  ),
                  if (deal['end_time'] != null)
                     DealCountdownTimer(endTime: DateTime.parse(deal['end_time'].toString())),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: dealColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: dealColor.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                height: 220,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: validProducts.length,
                  itemBuilder: (context, idx) {
                      final p = validProducts[idx];
                      return FlashDealProductCard(
                        item: p,
                        baseDiscountPercent: num.tryParse(deal['discount_percent']?.toString() ?? '0'),
                      );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildDailySavings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Savings', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF180331))),
              GestureDetector(
                onTap: () => context.push('/flash-deals'),
                child: const Text('View All', style: TextStyle(color: Color(0xFF006B5C), fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildSavingsCard(
                title: 'Get ₹50 OFF',
                subtitle: 'On your first order',
                icon: Icons.local_offer,
                bgColor: const Color(0xFF65FADE).withValues(alpha: 0.3),
                iconBgColor: const Color(0xFF006B5C),
              ),
              _buildSavingsCard(
                title: 'Free Delivery',
                subtitle: 'Above orders of ₹199',
                icon: Icons.delivery_dining,
                bgColor: const Color(0xFFFFDCBE),
                iconBgColor: Colors.orange.shade700,
              ),
              _buildSavingsCard(
                title: '10% Cashback',
                subtitle: 'Using HDFC Cards',
                icon: Icons.payments,
                bgColor: const Color(0xFFEEDBFF),
                iconBgColor: const Color(0xFF180331),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsCard({required String title, required String subtitle, required IconData icon, required Color bgColor, required Color iconBgColor}) {
    return GestureDetector(
      onTap: () => context.push('/flash-deals'),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF180331), fontSize: 14)),
              Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4A454E), fontSize: 10)),
            ],
          )
        ],
      ),
    ));
  }



  Widget _buildShopByCategory(WidgetRef ref) {
    final categoriesAsync = ref.watch(homeCategoriesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shop by Category',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF180331),
            ),
          ),
          const SizedBox(height: 16),
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return CategoryCard(category: categories[index]);
                },
              );
            },
            loading: () => Skeletonizer(
              enabled: true,
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            error: (err, _) => const Text(
              'Failed to load categories',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFeed(WidgetRef ref) {
    final groupedAsync = ref.watch(groupedProductsProvider);
    final bannersAsync = ref.watch(bannersProvider);

    return groupedAsync.when(
      data: (groupedCategories) {
        if (groupedCategories.isEmpty) return const SizedBox.shrink();
        
        final banners = bannersAsync.maybeWhen(data: (d) => d, orElse: () => <Map<String, dynamic>>[]);
        
        final List<HomeItem> feed = [];
        final Set<String> placedBannerIds = {};

        // 1. Add banners placed at the very top (or null/empty)
        for (final banner in banners) {
          final p = banner['placement_after']?.toString().toLowerCase();
          
          if (p == 'hero') continue;
          
          if (p == null || p == '' || p == 'top') {
            feed.add(HomeItem.banner(banner));
            placedBannerIds.add(banner['id'].toString());
          }
        }

        // 2. Walk through categories in order
        for (final group in groupedCategories) {
          feed.add(HomeItem.category(group));
          final category = group['category'];
          final catId = category['id'];

          // 3. After category banners
          for (final banner in banners) {
            if (placedBannerIds.contains(banner['id'].toString())) continue;
            if (banner['placement_after']?.toString().toLowerCase() == 'hero') continue;
            if (banner['placement_after'] == 'after_category_$catId') {
              feed.add(HomeItem.banner(banner));
              placedBannerIds.add(banner['id'].toString());
            }
          }
        }

        // 4. Handle banners placed after other banners
        bool changed = true;
        while (changed) {
          changed = false;
          for (final banner in banners) {
            if (placedBannerIds.contains(banner['id'].toString())) continue;
            if (banner['placement_after']?.toString().toLowerCase() == 'hero') continue;
            final p = banner['placement_after']?.toString();
            if (p != null && p.startsWith('after_banner_')) {
              final refId = p.replaceFirst('after_banner_', '');
              
              final refIndex = feed.indexWhere(
                (item) => item.type == HomeItemType.banner && item.banner!['id'].toString() == refId
              );
              
              if (refIndex != -1) {
                feed.insert(refIndex + 1, HomeItem.banner(banner));
                placedBannerIds.add(banner['id'].toString());
                changed = true;
              }
            }
          }
        }

        // 5. Unplaced banners at the end
        for (final banner in banners) {
          if (!placedBannerIds.contains(banner['id'].toString())) {
            feed.add(HomeItem.banner(banner));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: feed.map((item) {
            if (item.type == HomeItemType.banner) {
               return Padding(
                 padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                 child: _buildGenericBanner(item.banner!),
               );
            } else {
               final group = item.categoryGroup!;
               final category = group['category'];
               return Padding(
                 padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(category['name']?.toString() ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF180331))),
                         GestureDetector(
                           onTap: () {
                              context.push('/CategoryModel/${category['id']}', extra: category['name']?.toString() ?? '');
                           },
                           child: const Text('See all', style: TextStyle(color: Color(0xFF006B5C), fontWeight: FontWeight.bold, fontSize: 14)),
                         )
                       ],
                     ),
                     const SizedBox(height: 16),
                     GridView.builder(
                       padding: EdgeInsets.zero,
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(),
                       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                         crossAxisCount: 3,
                         crossAxisSpacing: 8,
                         mainAxisSpacing: 16,
                         mainAxisExtent: 320,
                       ),
                       itemCount: (group['products'] as List).length,
                       itemBuilder: (context, index) {
                         return ProductCard(product: (group['products'] as List)[index] as Map<String, dynamic>);
                       },
                     ),
                   ],
                 ),
               );
            }
          }).toList(),
        );
      },
      loading: () => Skeletonizer(
        enabled: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 16, mainAxisExtent: 320

            ),
            itemCount: 6,
            itemBuilder: (context, index) => Container(
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
      error: (err, _) => const Padding(padding: EdgeInsets.all(24), child: Text('Failed to load products', style: TextStyle(color: Colors.red))),
    );
  }

  void _handleBannerTap(BuildContext context, Map<String, dynamic> b) {
     final type = b['redirect_type'];
     if (type == 'category') {
        context.push('/CategoryModel/${b['redirect_id'] ?? ''}', extra: b['title']);
     } else if (type == 'product') {
        context.push('/ProductModel/${b['redirect_id']}'); 
     } else if (type == 'url') {
        // Handle URL launch if needed
     } else {
        context.push('/flash-deals');
     }
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return Colors.indigo;
    switch (colorStr.toLowerCase()) {
      case 'red': return const Color(0xFFE53935);
      case 'blue': return const Color(0xFF1E88E5);
      case 'green': return const Color(0xFF43A047);
      case 'orange': return const Color(0xFFFB8C00);
      case 'purple': return const Color(0xFF8E24AA);
      case 'yellow': return const Color(0xFFFDD835);
      case 'teal': return const Color(0xFF00897B);
    }
    if (colorStr.startsWith('#')) {
      try {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {}
    }
    return Colors.indigo;
  }

  Widget _buildGenericBanner(Map<String, dynamic> b) {
      Color bg = _parseColor(b['background_color']); 
      final String alignRaw = b['text_alignment']?.toString() ?? 'left';
      final String colorRaw = b['text_color']?.toString() ?? 'white';
      
      CrossAxisAlignment crossAlign = CrossAxisAlignment.start;
      TextAlign textAlign = TextAlign.left;
      if (alignRaw == 'center') {
        crossAlign = CrossAxisAlignment.center;
        textAlign = TextAlign.center;
      } else if (alignRaw == 'right') {
        crossAlign = CrossAxisAlignment.end;
        textAlign = TextAlign.right;
      }
      
      Color titleColor = colorRaw == 'dark' ? Colors.black87 : Colors.white;
      Color subtitleColor = colorRaw == 'dark' ? Colors.black54 : Colors.white;

      return GestureDetector(
        onTap: () => _handleBannerTap(context, b),
        child: Container(
          width: double.infinity,
          height: 140,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (b['image_url'] != null && b['image_url'].toString().isNotEmpty)
                  AppNetworkImage(
                    imageUrl: b['image_url'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                if (b['image_url'] != null && b['image_url'].toString().isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: alignRaw == 'right' ? Alignment.centerRight : Alignment.centerLeft,
                        end: alignRaw == 'right' ? Alignment.centerLeft : Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: crossAlign,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(b['title'] ?? '', textAlign: textAlign, style: TextStyle(color: titleColor, fontSize: 20, fontWeight: FontWeight.bold)),
                      if (b['subtitle'] != null) ...[
                        const SizedBox(height: 4),
                        Text(b['subtitle'], textAlign: textAlign, style: TextStyle(color: subtitleColor, fontSize: 14)),
                      ],
                    ]
                  )
                )
              ]
            )
          )
        )
      );
  }
}

class CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    List<String> images = (category['images'] as List<dynamic>?)?.cast<String>() ?? [];
    int count = category['totalCount'] ?? 0;
    
    int remaining = count > 4 ? count - 4 : 0;
    
    return GestureDetector(
      onTap: () {
        context.push('/CategoryModel/${category['id']}', extra: category['name']);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            // Image Collage Part
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // 2x2 Grid container
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(4),
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          final hasImage = index < images.length && images[index].isNotEmpty;
                          Widget img = hasImage
                              ? AppNetworkImage(
                                  imageUrl: images[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade200, 
                                    child: const Icon(Icons.broken_image, size: 16, color: Colors.grey),
                                  )
                                )
                              : Container(
                                  color: Colors.grey.shade200, 
                                  child: const Icon(Icons.image, color: Colors.grey, size: 16)
                                );
                          
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: img,
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Pill Badge overlay
                  if (remaining > 0)
                    Positioned(
                      bottom: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                          border: Border.all(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Text(
                          '+$remaining more',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 18),
            
            // Category Name
            Text(
              category['name'] ?? '', 
              style: const TextStyle(
                fontWeight: FontWeight.w800, 
                fontSize: 12, 
                color: Color(0xFF1A1C1D),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Dynamic fallback field mapping from Supabase specs
    final salePrice = product['sale_price'] ?? product['discounted_price'];
    final basePrice = product['price'] ?? 0;
    final price = salePrice ?? basePrice;
    final mrp = product['mrp']; 
    final unitLabel = product['unit'] ?? product['unit_size'] ?? '';
    final discountPercent = (mrp != null && mrp > price && mrp > 0) ? (((mrp - price) / mrp) * 100).toInt() : 0;
    
    return GestureDetector(
      onTap: () {
        if (product['id'] != null) {
          context.push('/ProductModel/${product['id']}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top image stack
          Expanded(
            flex: 50,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CachedNetworkImage(
                        imageUrl: product['image_url'] ?? '',
                        fit: BoxFit.contain,
                        errorWidget: (context, url, error) => const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                // Heart Fav Icon
                const Positioned(
                  top: 16,
                  right: 16,
                  child: Icon(Icons.favorite_border, color: Colors.grey, size: 18),
                ),
                // Discount Badge
                if (discountPercent > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDB4437),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                // ADD Button
                Positioned(
                  bottom: -6,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF006B5C)),
                      borderRadius: BorderRadius.circular(8),
                      // Drop shadow to lift the button
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: const Text('ADD', style: TextStyle(color: Color(0xFF006B5C), fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
          
          // Details section
          Expanded(
            flex: 50, 
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Veg Dot & Weight
                  Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(border: Border.all(color: Colors.green.shade700), borderRadius: BorderRadius.circular(2)),
                        child: Center(child: Icon(Icons.circle, size: 4, color: Colors.green.shade700)),
                      ),
                      const SizedBox(width: 4),
                      Text(unitLabel, style: TextStyle(fontSize: 9, color: Colors.grey.shade700, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Product Name
                  SizedBox(
                    height: 32, // Fixed height for 2 lines
                    child: Text(
                      product['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.2, color: Color(0xFF1A1C1D)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Ratings (Mocked count but star rating is part of design)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 10),
                      const Icon(Icons.star, color: Colors.amber, size: 10),
                      const Icon(Icons.star, color: Colors.amber, size: 10),
                      const Icon(Icons.star, color: Colors.amber, size: 10),
                      const Icon(Icons.star_half, color: Colors.amber, size: 10),
                      const SizedBox(width: 4),
                      Text('(2.1k)', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Delivery Time
                  const Row(
                    children: [
                      Icon(Icons.schedule, size: 10, color: Color(0xFF006B5C)),
                      SizedBox(width: 4),
                      Text('8 MINS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF006B5C))),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Price
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text('₹$price', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        if (mrp != null && mrp > price) ...[
                          const SizedBox(width: 4),
                          Text('₹$mrp', style: TextStyle(decoration: TextDecoration.lineThrough, fontSize: 10, color: Colors.grey.shade500)),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // See more button
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006B5C).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'See more like this',
                            style: TextStyle(color: Color(0xFF006B5C), fontSize: 9, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.play_arrow, color: Color(0xFF006B5C), size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

// ─── Dynamic Hero Carousel ───────────────────────────────────────────────────

class _DynamicHeroCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final void Function(BuildContext, Map<String, dynamic>) onTap;

  const _DynamicHeroCarousel({required this.banners, required this.onTap});

  @override
  State<_DynamicHeroCarousel> createState() => _DynamicHeroCarouselState();
}

class _DynamicHeroCarouselState extends State<_DynamicHeroCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      // Auto-scroll every 4 s
      Future.delayed(const Duration(seconds: 4), _autoScroll);
    }
  }

  void _autoScroll() {
    if (!mounted) return;
    final next = (_currentPage + 1) % widget.banners.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 4), _autoScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.banners.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final b = widget.banners[index];
                final hasImage =
                    b['image_url'] != null && b['image_url'].toString().isNotEmpty;

                final String alignRaw = b['text_alignment']?.toString() ?? 'left';
                final String colorRaw = b['text_color']?.toString() ?? 'white';
                final String sizeRaw = b['banner_size']?.toString() ?? 'full_width';

                CrossAxisAlignment crossAlign = CrossAxisAlignment.start;
                TextAlign textAlign = TextAlign.left;
                if (alignRaw == 'center') {
                  crossAlign = CrossAxisAlignment.center;
                  textAlign = TextAlign.center;
                } else if (alignRaw == 'right') {
                  crossAlign = CrossAxisAlignment.end;
                  textAlign = TextAlign.right;
                }

                Color textColorPrimary = colorRaw == 'dark' ? Colors.black87 : Colors.white;
                Color textColorSecondary = colorRaw == 'dark' ? Colors.black54 : Colors.white70;

                double? explicitWidth;
                if (sizeRaw == 'half_width') {
                  explicitWidth = MediaQuery.of(context).size.width * 0.5;
                } else if (sizeRaw == 'square') {
                  explicitWidth = 200.0; // constrained by PageView 200 height
                }

                return GestureDetector(
                  onTap: () => widget.onTap(context, b),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: explicitWidth,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: const Color(0xFFFFB870),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: b['image_url'],
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    Container(color: const Color(0xFFFFB870)),
                              ),
                              // Gradient overlay for text legibility
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.55),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: alignRaw == 'right' ? null : 24,
                                right: alignRaw == 'left' ? null : 24,
                                bottom: 24,
                                child: Column(
                                  crossAxisAlignment: crossAlign,
                                  children: [
                                    if (b['badge_text'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        margin: const EdgeInsets.only(bottom: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          b['badge_text'],
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    Text(
                                      b['title'] ?? '',
                                      textAlign: textAlign,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: textColorPrimary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    if (b['subtitle'] != null)
                                      Text(
                                        b['subtitle'],
                                        textAlign: textAlign,
                                        style: TextStyle(
                                          color: textColorSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        // No image: gradient card with text
                        : Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: crossAlign,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  b['title'] ?? '',
                                  textAlign: textAlign,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: colorRaw == 'dark' ? const Color(0xFF180331) : Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 28,
                                  ),
                                ),
                                if (b['subtitle'] != null) ...[
                                  const SizedBox(height: 6),
                                  Text(b['subtitle'],
                                      textAlign: textAlign,
                                      style: TextStyle(
                                          color: colorRaw == 'dark' ? const Color(0xFF693C00) : Colors.white70,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                ],
                              ],
                            ),
                          ),
                  ),
                ));
              },
            ),
          ),
          // Dot indicators — only shown when > 1 banner
          if (widget.banners.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.banners.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentPage ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? const Color(0xFF006B5C)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
