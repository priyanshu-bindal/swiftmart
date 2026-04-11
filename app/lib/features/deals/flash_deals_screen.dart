import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'providers/flash_deals_provider.dart';
import 'widgets/flash_deal_product_card.dart';
import 'widgets/deal_countdown_timer.dart';

// Helper function
Color _parseColor(String hexString, Color defaultColor) {
  if (hexString.isEmpty) return defaultColor;
  try {
    final hexColor = hexString.replaceAll('#', '');
    if (hexColor.length == 6) {
      return Color(int.parse('FF$hexColor', radix: 16));
    } else if (hexColor.length == 8) {
      return Color(int.parse(hexColor, radix: 16));
    }
  } catch (e) {
    // ignore
  }
  return defaultColor;
}

class FlashDealsScreen extends HookConsumerWidget {
  const FlashDealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flashDealsFutureProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),
      appBar: AppBar(
        title: Text(
          '⚡ Flash Deals',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6C3CE1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(flashDealsFutureProvider);
        },
        child: state.when(
          data: (deals) {
            if (deals.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 100,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_off, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No flash deals right now.\nCheck back soon!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: deals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final deal = deals[index];
                final dealColor = _parseColor(deal['badge_color']?.toString() ?? '', const Color(0xFFFF4444));
                final productsList = deal['flash_deal_products'] as List? ?? [];
                // Only show products within the deal that have 'products' joined successfully
                final validProducts = productsList.where((p) => p['products'] != null).toList();

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: dealColor.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      Container(
                        color: dealColor,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    deal['title'] ?? 'Special Offer',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                if (deal['end_time'] != null)
                                  DealCountdownTimer(endTime: DateTime.parse(deal['end_time'].toString())),
                              ],
                            ),
                            if (deal['subtitle'] != null && deal['subtitle'].toString().trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                deal['subtitle'].toString(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      
                      // Products Horizontal List
                      Container(
                        height: 220,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: dealColor.withValues(alpha: 0.05),
                        child: validProducts.isEmpty
                            ? const Center(child: Text("No items available"))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemCount: validProducts.length,
                                itemBuilder: (context, idx) {
                                  final p = validProducts[idx];
                                  return FlashDealProductCard(
                                    item: p,
                                    baseDiscountPercent: num.tryParse(deal['discount_percent']?.toString() ?? '0'),
                                  ).animate().fadeIn(delay: (50 * idx).ms).slideX(begin: 0.1, end: 0);
                                },
                              ),
                      ),
                    ],
                  ),
                ).animate(delay: (100 * index).ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF6C3CE1)),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Error: $err',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
