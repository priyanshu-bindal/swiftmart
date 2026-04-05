import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'widgets/animated_bottom_nav.dart';

// Provider to fetch banners
final bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  return await supabase.from('banners').select().eq('is_active', true).order('sort_order', ascending: true);
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

class HomeScreen extends StatefulHookConsumerWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF006B5C),
          onRefresh: () async {
            ref.invalidate(homeCategoriesProvider);
            ref.invalidate(groupedProductsProvider);
            ref.invalidate(bannersProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(context),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 24),
                _buildHeroBanner(),
                const SizedBox(height: 32),
                _buildDailySavings(),
                const SizedBox(height: 32),
                _buildShopByCategory(ref),
                _buildBannerSection(ref, 'categories'),
                _buildGroupedProducts(ref),
                const SizedBox(height: 120), // Spacing for bottom nav
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SwiftmartBottomNav(
        currentTab: const ['home', 'category', 'orders', 'cart'][_selectedIndex],
        onTabSelected: (tab) {
           int i = const ['home', 'category', 'orders', 'cart'].indexOf(tab);
           if (i == 0) return; // Already on Home
           
           if (i == 1) {
             context.push('/browse_categories');
           } else if (i == 2) {
             context.push('/OrderModel-history');
           } else if (i == 3) {
             context.push('/cart');
           }
        },
      ),
      extendBody: true,
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
                  image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuA199lxjUYB1dc1Q45OLCjH3X_0-WRUfpNhLMKb1R8owyAEAgIJkYc_quYiJJpds4-xeebvNGtYH-G132SHjvXrbJMMyfkpemsCpUUGQlruHhf9OtwgFuemi8zSMZgOYMmSLgylyj_d5WVSOKPb_MVkkplX28ftssCtQmDvFViPkncWvzNl1UKweA6U9AOHvDXku39H-fTNnbMsd_WoMdUDv7YjZl2BJxFN0-illwsVt5OHO3Q3hXFyipC63mOdPeutFmYWCmyewqoa'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
    );
  }

  Widget _buildHeroBanner() {
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
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuC8oFOM_oJjC9Mns4dTa2OHbmOIOwH-CFsRb-EER7nXmpzhaJQfsil8n2kePN0G0QSuO_uoa8xqAc50kT1xvyHUtYsw0V28ptz4lVSP9sg0pJyrensZqeLC6pnYRViwsI58z4V7wiWpCT7TBF3A559b9iDD1r8_9LOPJvgH8vJZVxLiBI-X0EJeXDW7nzJ0fZxB9epgvS-ciKnuq1WuztU5cTPbbM2eW-oMc_kb9UIuXdgo452zDBEA-ws-LrrztmPnwVBOe3faAOzP',
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
              const Text('View All', style: TextStyle(color: Color(0xFF006B5C), fontWeight: FontWeight.bold, fontSize: 14)),
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
    return Container(
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
    );
  }

  Widget _buildShopByCategory(WidgetRef ref) {
    final categoriesAsync = ref.watch(homeCategoriesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shop by Category', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF180331))),
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
                  crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 16, childAspectRatio: 0.65
                ),
                itemCount: 4,
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            error: (err, _) => const Text('Failed to load categories', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedProducts(WidgetRef ref) {
    final groupedAsync = ref.watch(groupedProductsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: groupedAsync.when(
        data: (groupedCategories) {
          if (groupedCategories.isEmpty) return const SizedBox.shrink();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: groupedCategories.map((group) {
              final category = group['category'];
              final products = group['products'] as List<dynamic>;
              final catName = category['name']?.toString() ?? '';
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(catName, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF180331))),
                      GestureDetector(
                        onTap: () {
                           context.push('/CategoryModel/${category['id']}', extra: catName);
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
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return ProductCard(product: products[index] as Map<String, dynamic>);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildBannerSection(ref, catName),
                ],
              );
            }).toList(),
          );
        },
        loading: () => Skeletonizer(
          enabled: true,
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
        error: (err, _) => const Text('Failed to load products', style: TextStyle(color: Colors.red)),
      ),
    );
  }

  void _handleBannerTap(BuildContext context, Map<String, dynamic> b) {
     final type = b['redirect_type'];
     if (type == 'category') {
        context.push('/CategoryModel/${b['redirect_id'] ?? ''}', extra: b['title']);
     } else if (type == 'product') {
        context.push('/ProductDetail/${b['redirect_id']}'); 
     } else if (type == 'url') {
        // Handle URL launch if needed
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

  Widget _buildBannerSection(WidgetRef ref, String position) {
    final bannersAsync = ref.watch(bannersProvider);
    return bannersAsync.when(
      data: (allBanners) {
        final positionBanners = allBanners
            .where((b) => (b['position_after'] ?? '').toString().toLowerCase() == position.toLowerCase())
            .toList();
            
        if (positionBanners.isEmpty) return const SizedBox(height: 16);
        
        Widget render;
        if (position.toLowerCase() == 'categories') {
           render = _buildSaleBanner(positionBanners.first);
        } else if (positionBanners.length >= 3) {
           render = _buildEventsBanner(positionBanners);
        } else {
           render = _buildGenericBanner(positionBanners.first);
        }
        return Padding(padding: const EdgeInsets.only(bottom: 24), child: render);
      },
      loading: () => const SizedBox(height: 16),
      error: (err, stack) => const SizedBox(height: 16),
    );
  }

  Widget _buildSaleBanner(Map<String, dynamic> banner) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF9A44), Color(0xFFFC6076)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(banner['title'] ?? 'SALE', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
          if (banner['subtitle'] != null) ...[
            const SizedBox(height: 4),
            Text(banner['subtitle'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              itemBuilder: (context, index) {
                 final mocks = [
                   {"discount": "50% OFF", "name": "Cooking", "img": "https://loremflickr.com/200/200/oil?lock=200"},
                   {"discount": "FLAT ₹50", "name": "Snacks", "img": "https://loremflickr.com/200/200/snack?lock=201"},
                   {"discount": "30% OFF", "name": "Cleaning", "img": "https://loremflickr.com/200/200/soap?lock=202"},
                   {"discount": "BUY 1 GET 1", "name": "Dairy", "img": "https://loremflickr.com/200/200/milk?lock=203"},
                 ];
                 return Container(
                   width: 90,
                   margin: const EdgeInsets.only(right: 12),
                   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                         decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                         child: Text(mocks[index]['discount']!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                       ),
                       const SizedBox(height: 6),
                       ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(mocks[index]['img']!, width: 40, height: 40, fit: BoxFit.cover)),
                       const SizedBox(height: 6),
                       Text(mocks[index]['name']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                     ],
                   ),
                 );
              }
            ),
          )
        ],
      )
    );
  }

  Widget _buildEventsBanner(List<Map<String, dynamic>> banners) {
    if (banners.length < 3) return const SizedBox.shrink();
    final big = banners[0];
    final small1 = banners[1];
    final small2 = banners[2];

    Widget buildCard(Map<String, dynamic> b, double height) {
      Color bg = _parseColor(b['background_color']); 
      return GestureDetector(
        onTap: () => _handleBannerTap(context, b),
        child: Container(
          height: height,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Stack(
            children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   if (b['badge_text'] != null)
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                       child: Text(b['badge_text'], style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                     ),
                   const SizedBox(height: 8),
                   Text(b['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                   if (b['subtitle'] != null) Text(b['subtitle'], style: const TextStyle(color: Colors.white, fontSize: 11)),
                 ],
               ),
               if (b['image_url'] != null && b['image_url'].toString().isNotEmpty)
                 Positioned(
                   bottom: 0, right: 0,
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(8),
                     child: Image.network(b['image_url'], width: height * 0.6, height: height * 0.6, fit: BoxFit.cover),
                   ),
                 )
            ]
          )
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Events this week', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(flex: 5, child: buildCard(big, 240)),
            const SizedBox(width: 12),
            Expanded(
              flex: 4, 
              child: Column(
                children: [
                  buildCard(small1, 114),
                  const SizedBox(height: 12),
                  buildCard(small2, 114),
                ]
              )
            )
          ]
        )
      ],
    );
  }

  Widget _buildGenericBanner(Map<String, dynamic> b) {
      Color bg = _parseColor(b['background_color']); 
      return GestureDetector(
        onTap: () => _handleBannerTap(context, b),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: 120,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(b['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      if (b['subtitle'] != null) Text(b['subtitle'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ]
                  )
                )
              ),
              if (b['image_url'] != null)
                ClipRRect(borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)), child: Image.network(b['image_url'], width: 120, height: 120, fit: BoxFit.cover)),
            ]
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
                              ? CachedNetworkImage(
                                  imageUrl: images[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade200, 
                                    child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 16)
                                  ),
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
