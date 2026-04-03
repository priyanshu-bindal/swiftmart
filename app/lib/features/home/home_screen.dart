import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../core/theme/app_colors.dart';
import '../cart/providers/cart_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart';
import 'models/sdui_models.dart';
import 'sdui_renderer.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

// Future Provider for fetching SDUI config from Supabase
final sduiConfigProvider = FutureProvider<SduiConfig>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('home_config')
      .select()
      .eq('is_active', true)
      .maybeSingle();

  var configData = response?['config'];
  
  if (configData is String) {
    try {
      configData = jsonDecode(configData);
    } catch (_) {}
  }

  if (configData == null || configData is! Map<String, dynamic>) {
    // Fallback if nothing found
    configData = {
      "sections": [
        {"type": "search_bar", "visible": true},
        {"type": "banner_carousel", "visible": true},
        {"type": "category_row", "title": "Shop by Category", "visible": true},
        {"type": "flash_deals_row", "title": "Flash Deals", "visible": true},
        {"type": "coupon_strip", "visible": true},
        {"type": "product_grid", "title": "Featured Products", "visible": true}
      ]
    };
  }

  return SduiConfig.fromJson(configData);
});

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sduiState = ref.watch(sduiConfigProvider);
    final userLocation = ref.watch(locationProvider);
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
                  GestureDetector(
                    onTap: userLocation == 'Set location'
                        ? () async {
                            await _showLocationSheet(context, ref);
                          }
                        : null,
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: userLocation == 'Set location' ? Colors.amber : AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DELIVER TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.outline)),
                            Text(
                              userLocation,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: userLocation == 'Set location' ? Colors.amber.shade700 : AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text('SwiftMart', style: GoogleFonts.manrope(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 28, letterSpacing: -1.0)),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C3CE1), Color(0xFF00D4AA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3), width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (() {
                          // Show initial of display name or email
                          try {
                            final user = ref.read(authProvider).user;
                            if (user?.displayName?.isNotEmpty == true) {
                              return user!.displayName![0].toUpperCase();
                            }
                            if (user?.email?.isNotEmpty == true) {
                              return user!.email![0].toUpperCase();
                            }
                          } catch (_) {}
                          return '?';
                        })(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
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

  Future<void> _showLocationSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HomeLocationSheet(
        onUseLocation: () async {
          Navigator.pop(context);
          await ref.read(locationProvider.notifier).requestAndUpdate();
        },
        onSkip: () {
          Navigator.pop(context);
        },
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


// ─── Location Bottom Sheet (used from HomeScreen AppBar) ──────────────────────

class _HomeLocationSheet extends StatelessWidget {
  final VoidCallback onUseLocation;
  final VoidCallback onSkip;

  const _HomeLocationSheet({required this.onUseLocation, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF6C3CE1);
    const teal = Color(0xFF00D4AA);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [violet, teal], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: violet.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            'Where should we deliver?',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1B21)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'SwiftMart needs your location to show nearby stores and deliver in under 30 minutes.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onUseLocation,
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [violet, teal]),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: violet.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              alignment: Alignment.center,
              child: const Text('Use My Location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onSkip,
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: violet.withValues(alpha: 0.4), width: 1.5),
              ),
              alignment: Alignment.center,
              child: const Text('Skip for now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: violet)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
