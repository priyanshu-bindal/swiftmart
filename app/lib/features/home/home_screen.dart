import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../cart/providers/cart_provider.dart';
import 'models/sdui_models.dart';
import 'sdui_renderer.dart';

// Mock Future Provider for 1s delay mimicking an API call
final sduiConfigProvider = FutureProvider<SduiConfig>((ref) async {
  await Future.delayed(const Duration(milliseconds: AppConstants.mockNetworkDelayMs));
  
  final mockJson = <String, dynamic>{
    "components": [
      { "type": "search_bar", "data": <String, dynamic>{} },
      { "type": "banner_carousel", "data": <String, dynamic>{} },
      { "type": "category_row", "data": <String, dynamic>{} },
      { "type": "flash_deals_row", "data": <String, dynamic>{} },
      { "type": "value_combos", "data": <String, dynamic>{} },
      { "type": "coupon_strip", "data": <String, dynamic>{} },
      { "type": "product_grid", "data": <String, dynamic>{} },
    ]
  };
  
  return SduiConfig.fromJson(mockJson);
});

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sduiState = ref.watch(sduiConfigProvider);
    final cartItemCount = ref.watch(cartProvider.select((items) => items.fold(0, (sum, i) => sum + i.quantity)));
    final cartTotal = ref.watch(cartProvider.select((items) => items.fold(0.0, (sum, i) => sum + (i.product.price * i.quantity))));

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: AppColors.background.withValues(alpha: 0.7),
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 24, right: 24, bottom: 16),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DELIVER TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.outline)),
                          const Text('Manhattan, NY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                        ],
                      ),
                    ],
                  ),
                  Text('SwiftMart', style: GoogleFonts.manrope(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 28, letterSpacing: -1.0)),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.2), width: 2),
                      image: const DecorationImage(
                        image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDOc_mAO8ASyMs13CHxcMjGiCAleZ0ALNsOIZj0xlUP0LIxd8rnUDVHuG02uqEMj0fDK34Dpz7Ead1C-iHezUSW8ETWIb750a0O_YevabiMixjw00pjvSXwzMspyIslFJdWHk7RUv7hR1r-N3wSQnVdxegCY69iEd0EsLbxcGclF300wwMdfjb_Z_hMCThmY5le0k2QOxdI7ZbbHnsi9IMvlnMNH7DRjeLdCylXCCzmzLUlwORjMmvlkPXbvFRr2vL61ShbvdTnp9a5'), // Profile Image
                        fit: BoxFit.cover,
                      )
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      body: sduiState.when(
        data: (config) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sduiConfigProvider),
            child: ListView.separated(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 80,
                bottom: 120 + (cartItemCount > 0 ? 80 : 0),
              ),
              itemCount: config.components.length,
              separatorBuilder: (_, _) => const SizedBox(height: 40),
              itemBuilder: (context, index) {
                return SduiRenderer.render(config.components[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Glassmorphic Bottom Nav
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 96,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest.withValues(alpha: 0.7),
                  boxShadow: [
                    BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.08), offset: const Offset(0, -16), blurRadius: 32),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavIcon(Icons.auto_awesome, 'Atelier', true, onTap: () {}),
                    _buildNavIcon(Icons.search, 'Search', false, onTap: () => context.push('/search')),
                    _buildNavIcon(Icons.shopping_bag_outlined, 'Cart', false, onTap: () => context.push('/cart')),
                    _buildNavIcon(Icons.receipt_long, 'Orders', false, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
          
          // Floating Cart Status
          if (cartItemCount > 0)
            Positioned(
              bottom: 112,
              left: 24,
              right: 24,
              child: GestureDetector(
                onTap: () => context.push('/cart'),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), offset: const Offset(0, 8), blurRadius: 16),
                    ]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.shopping_bag, color: AppColors.onPrimary, size: 32),
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Text('$cartItemCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.onSecondaryContainer)),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$cartItemCount ITEMS', style: TextStyle(color: AppColors.onPrimary.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('\$${cartTotal.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.onPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                            ],
                          )
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.onPrimary, borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Text('VIEW CART', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, color: AppColors.primary, size: 16)
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? AppColors.primary : Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: isActive ? AppColors.primary : Colors.grey.shade400)),
          if (isActive) ...[
            const SizedBox(height: 4),
            Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
          ]
        ],
      ),
    );
  }
}
