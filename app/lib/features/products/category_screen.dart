import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../shared/widgets/app_network_image.dart';

class SubcategoryItem {
  final String name;
  final String imageUrl;

  SubcategoryItem({required this.name, required this.imageUrl});
}

final rawCategoryProductsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, categoryId) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('products')
      .select('id, name, brand, image_url, category_id, price, discounted_price, mrp, sale_price, unit, unit_size, stock_qty, is_active, tags, subcategory')
      .eq('category_id', categoryId)
      .eq('is_active', true)
      .order('name', ascending: true);
  return List<Map<String, dynamic>>.from(response);
});

class CategoryScreen extends StatefulHookConsumerWidget {
  final String categoryId;
  final String categoryName;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  String _selectedSubcategory = 'All';
  bool _isSwitching = false;

  List<SubcategoryItem> _extractSubcategories(List<Map<String, dynamic>> products) {
    final map = <String, String>{};
    for (var p in products) {
      final sub = p['subcategory']?.toString();
      if (sub == null || sub.trim().isEmpty) continue;
      if (!map.containsKey(sub)) {
        map[sub] = p['image_url']?.toString() ?? '';
      }
    }

    final list = <SubcategoryItem>[
      SubcategoryItem(
        name: 'All', 
        imageUrl: 'https://loremflickr.com/100/100/vegetables,grocery?lock=0'
      )
    ];

    map.forEach((name, img) {
      list.add(SubcategoryItem(
        name: name,
        imageUrl: img.isNotEmpty ? img : 'https://loremflickr.com/100/100/${Uri.encodeComponent(name)}',
      ));
    });

    return list;
  }

  void _onSubcategoryTapped(String subName) {
    if (_selectedSubcategory == subName) return;
    setState(() {
      _selectedSubcategory = subName;
      _isSwitching = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isSwitching = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(rawCategoryProductsProvider(widget.categoryId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(context),
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final subcategories = _extractSubcategories(products);
                    final displayedProducts = _selectedSubcategory == 'All'
                        ? products
                        : products.where((p) => p['subcategory']?.toString() == _selectedSubcategory).toList();

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSidebar(subcategories),
                        Container(width: 1, color: Colors.grey.shade200),
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: _isSwitching
                                ? _buildSkeletonGrid()
                                : _buildProductGrid(displayedProducts),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSkeletonSidebar(),
                        Container(width: 1, color: Colors.grey.shade200),
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: _buildSkeletonGrid(),
                          ),
                        ),
                      ],
                    );
                  },
                  error: (err, stack) => Center(
                    child: Text('Failed to load products: ${err.toString()}', style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back, color: Color(0xFF1A1C1D)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF292A2C),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.white54, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Search for atta, dal, coke and more',
                            style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Icon(Icons.mic, color: Colors.white54, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.categoryName,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: const Color(0xFF333333),
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Colors.black12),
      ],
    );
  }

  Widget _buildSidebar(List<SubcategoryItem> subcategories) {
    return SizedBox(
      width: 85,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final sub = subcategories[index];
          final isActive = sub.name == _selectedSubcategory;

          return GestureDetector(
            onTap: () => _onSubcategoryTapped(sub.name),
            child: Container(
              color: isActive ? Colors.green.shade50.withValues(alpha: 0.3) : Colors.transparent,
              child: Stack(
                children: [
                  if (isActive)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00897B), // Matches border in image
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: isActive ? const Color(0xFF00897B) : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isActive
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                          ),
                          child: ClipOval(
                            child: AppNetworkImage(
                              imageUrl: sub.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) => Container(
                                color: Colors.grey.shade100,
                                child: const Icon(Icons.grass, color: Colors.grey, size: 20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sub.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                            color: isActive ? const Color(0xFF333333) : Colors.grey.shade600,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return const Center(child: Text('No products available.', style: TextStyle(color: Colors.grey)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 330, // Optimized height
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        final double mrp = (p['mrp'] ?? p['price'] ?? 0).toDouble();
        final double sale = (p['sale_price'] ?? p['discounted_price'] ?? 0).toDouble();
        int discount = mrp > 0 ? ((mrp - sale) / mrp * 100).round() : 0;
        if (discount < 0) discount = 0;
        int stock = (p['stock_qty'] ?? 0).toInt();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 140, // Image area
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Container(
                        color: const Color(0xFFF6F5ED), // natural food bg
                        child: p['image_url'] != null && p['image_url'].toString().isNotEmpty
                            ? AppNetworkImage(
                                imageUrl: p['image_url'],
                                width: double.infinity,
                                height: 140,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => const Icon(Icons.image, color: Colors.grey),
                              )
                            : const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.favorite_border, color: Colors.white, size: 20),
                    ),
                    Positioned(
                      bottom: -14,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF00897B)), // matched to ref
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Text('ADD', style: TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${p['unit_size'] ?? 1} ${p['unit'] ?? 'pc'}",
                      style: TextStyle(color: Colors.blue.shade800, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.2, color: Color(0xFF333333)), // dark exact color
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.timer, color: Colors.green.shade600, size: 12),
                        const SizedBox(width: 4),
                        Text('8 MINS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.green.shade700)),
                      ],
                    ),
                    if (stock < 10)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Only $stock left', style: TextStyle(color: Colors.orange.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    if (discount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('$discount% OFF', style: TextStyle(color: Colors.blue.shade800, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹$sale', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF333333))),
                        const SizedBox(width: 6),
                        if (mrp > sale) Text('MRP ₹$mrp', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEDF7ED), borderRadius: BorderRadius.circular(4)), // exact light green
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "See ${5 + ((p['name'] ?? '').hashCode.abs() % 25)} recipes",
                      style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.play_arrow, color: Colors.green.shade800, size: 14),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 330,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 140,
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 40, height: 10, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: double.infinity, height: 14, color: Colors.white),
                      const SizedBox(height: 4),
                      Container(width: 80, height: 14, color: Colors.white),
                      const SizedBox(height: 12),
                      Container(width: 60, height: 12, color: Colors.white),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(8),
                  height: 24,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonSidebar() {
    return Container(
      width: 85,
      color: Colors.white,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade100,
            child: Column(
              children: [
                Container(width: 50, height: 50, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(height: 8),
                Container(width: 50, height: 10, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
