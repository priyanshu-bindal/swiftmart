import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/local_storage/database_helper.dart';
import '../../widgets/product_card.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';

final searchResultsProvider = FutureProvider.family<List<Product>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.read(productRepositoryProvider);
  return repo.fetchProducts(search: query);
});

class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');
    final recentSearches = useState<List<String>>([]);

    void loadRecents() async {
      final recents = await DatabaseHelper.instance.getRecentSearches();
      if (context.mounted) recentSearches.value = recents;
    }

    useEffect(() {
      loadRecents();
      return null;
    }, []);

    final debounceTimer = useRef<Timer?>(null);

    // Debounce search state update to prevent lag
    useEffect(() {
      void listener() {
        if (searchQuery.value != searchController.text) {
          if (searchController.text.isEmpty) {
            // Bypass debounce for instant clear
            debounceTimer.value?.cancel();
            searchQuery.value = '';
          } else {
            debounceTimer.value?.cancel();
            debounceTimer.value = Timer(const Duration(milliseconds: 300), () {
              if (context.mounted) {
                searchQuery.value = searchController.text;
              }
            });
          }
        }
      }

      searchController.addListener(listener);
      return () {
        searchController.removeListener(listener);
        debounceTimer.value?.cancel();
      };
    }, [searchController]);

    // Save to DB when user finishes typing (debounce DB write only)
    useEffect(() {
      final timer = Future.delayed(const Duration(milliseconds: 1000), () {
        if (searchQuery.value.trim().isNotEmpty) {
          DatabaseHelper.instance.addRecentSearch(searchQuery.value.trim());
        }
      });
      return () => timer.ignore();
    }, [searchQuery.value]);

    final hasQuery = searchQuery.value.trim().isNotEmpty;
    const bgBase = Color(0xFFFDFBFF);

    return Scaffold(
      backgroundColor: bgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopSection(context, searchController),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: hasQuery
                    ? _buildSearchResultsArea(
                        ref,
                        searchQuery.value,
                        searchController,
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildRecentSearches(
                              recentSearches.value,
                              searchController,
                              loadRecents,
                            ),
                            const SizedBox(height: 16),
                            _buildTrendingNow(searchController),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(
    BuildContext context,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
      color: const Color(0xFFFDFBFF),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF6C3CE1)),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0F8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search for groceries',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9E9CA7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    color: Color(0xFF9E9CA7),
                    size: 18,
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            color: Color(0xFF6C3CE1),
                            size: 18,
                          ),
                          onPressed: () => controller.clear(),
                        )
                      : const Icon(
                          LucideIcons.mic,
                          color: Color(0xFF6C3CE1),
                          size: 18,
                        ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1E1E),
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 44,
            width: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F0F8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                LucideIcons.listFilter,
                color: Color(0xFF333333),
                size: 18,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(
    List<String> searches,
    TextEditingController controller,
    VoidCallback loadRecents,
  ) {
    // If no recent searches from DB, put default ones as mock
    final displaySearches = searches.length > 3
        ? searches.take(6).toList()
        : ['Bread', 'Milk', 'Avocado', 'Greek Yogurt', 'Juice'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (searches.isNotEmpty)
                  InkWell(
                    onTap: () async {
                      await DatabaseHelper.instance.clearRecentSearches();
                      loadRecents();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF7A869A),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: displaySearches
                .map(
                  (query) =>
                      InkWell(
                        onTap: () {
                          controller.text = query;
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.clock,
                                size: 12,
                                color: Color(0xFF7A869A),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                query,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFF4A4A5A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().scale(
                        curve: Curves.easeOutBack,
                        duration: 400.ms,
                      ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingNow(TextEditingController controller) {
    final trending = [
      {
        'title': 'Mangoes 🥭',
        'bg': [const Color(0xFFE0FAF6), const Color(0xFFD0F2ED)],
        'text': const Color(0xFF00966D),
      },
      {
        'title': 'Cold Drinks 🥤',
        'bg': [const Color(0xFFF0EDFA), const Color(0xFFE6E2F5)],
        'text': const Color(0xFF6C3CE1),
      },
      {
        'title': 'Ice Cream 🍦',
        'bg': [const Color(0xFFFDF0E6), const Color(0xFFFDEAE6)],
        'text': const Color(0xFFD96350),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              'Trending Now',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: trending
                .map(
                  (t) =>
                      InkWell(
                        onTap: () {
                          // Remove emoji for accurate searching against DB
                          final rawTitle = (t['title'] as String)
                              .replaceAll(RegExp(r'[^\w\s]'), '')
                              .trim();
                          controller.text = rawTitle;
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: t['bg'] as List<Color>,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: t['text'] as Color,
                            ),
                          ),
                        ),
                      ).animate().scale(
                        curve: Curves.easeOutBack,
                        duration: 400.ms,
                      ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsArea(
    WidgetRef ref,
    String query,
    TextEditingController controller,
  ) {
    final searchState = ref.watch(searchResultsProvider(query));

    return searchState.when(
      data: (products) {
        if (products.isEmpty) {
          // EMPTY STATE ONLY WHEN QUERY EXISTS & 0 RESULTS
          return _buildEmptyState(controller);
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Search Results',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${products.length} items found',
                    style: const TextStyle(
                      color: Color(0xFF7A869A),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildGrid(products, isSkeleton: false)),
          ],
        );
      },
      loading: () => _buildGrid(mockProducts(), isSkeleton: true),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildGrid(List<Product> products, {required bool isSkeleton}) {
    return Skeletonizer(
      enabled: isSkeleton,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.60,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final card = ProductCard(product: product);
          return isSkeleton
              ? card
              : card.animate().fadeIn(
                  duration: 400.ms,
                  curve: Curves.easeOutQuad,
                );
        },
      ),
    );
  }

  Widget _buildEmptyState(TextEditingController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120, // Reduced icon size
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFF3EDFD),
                shape: BoxShape.circle,
              ),
            ),
            const Positioned(
              child: Icon(
                LucideIcons.searchX,
                size: 48,
                color: Color(0xFFBCA6F1),
              ),
            ),
            Positioned(
              bottom: 5,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: const Icon(
                  Icons.eco,
                  color: Color(0xFF006C4F),
                  size: 14,
                ),
              ),
            ),
          ],
        ).animate().scale(curve: Curves.elasticOut, duration: 800.ms),
        const SizedBox(height: 24),
        const Text(
          'No results found',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "We couldn't find anything matching your search.\nTry adjusting your filters or check for typos.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF5E5E6E),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 32),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: const Color(0xFF4C00D6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          onPressed: () {
            controller.clear();
          },
          child: const Text(
            'Clear Filters',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ).animate().fade(delay: 200.ms),
      ],
    );
  }

  List<Product> mockProducts() {
    return List.generate(
      4,
      (index) => Product(
        id: 'mock$index',
        name: 'Loading...',
        imagePath: '',
        price: 9.99,
        unit: '500 g',
        isOrganic: false,
      ),
    );
  }
}
