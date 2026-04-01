import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../cart/providers/cart_provider.dart';
import 'repositories/product_repository.dart';
import 'models/product.dart';

// Dummy Hardcoded Product for matching the exact HTML requirement
// This will be replaced by real API data later.
final dummyProduct = Product(
  id: 'str123',
  name: 'Lush Organic Strawberries',
  imagePath: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDKML3FZgtmkH51qd_K5JTSfQcqKD_XbMZA3-a4_phZ9vUbLs99yLR94aps-Pa84st8tQJbQxBi9JD_lU5sCRMDBrRLpb09tnAjBOLuaYkBoDARNs0jrSxZhl148SoGoRBRNxHLS1aZZxiwDSLuEAiL3rpPtg1Z33RFPGm0hnOTzIuDjgP4KUg80_pvKPZTY684BgSplSZOVzz6UMDJQTaDDMGwKAeGczrh53RH8AcoehPuVJlBT0XCSw2ec2QahbhsR1TZVb6WDEGS',
  price: 240,
  unit: '1 box',
  brand: 'Farm Fresh Collective',
  isOrganic: true,
  rating: 4.5,
  reviewCount: 128,
  originalPrice: 300,
  discountPercentage: 20,
  cashback: 20,
  description: 'Our premium organic strawberries are hand-picked at peak ripeness. They are grown without synthetic pesticides, ensuring a sweeter, more intense flavor and vibrant natural color. Perfect for breakfast bowls or healthy snacking.',
);

class ProductDetailScreen extends HookConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Stage the local count purely for UI before committing to Cart
    final localCount = useState(1);
    
    // Fetch right Product from repo or fallback to dummy
    final product = ref.read(productRepositoryProvider).getProductById(productId) ?? dummyProduct;

    final cartItemCount = ref.watch(cartProvider.select((items) => items.fold(0, (sum, i) => sum + i.quantity)));
    final cartTotal = ref.watch(cartProvider.select((items) => items.fold(0.0, (sum, i) => sum + (i.product.price * i.quantity))));

    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.7),
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16, right: 16, bottom: 8),
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.primaryContainer),
                        onPressed: () => context.pop(),
                      ),
                      Text('SwiftMart', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryContainer)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.favorite, color: AppColors.outline), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.share, color: AppColors.outline), onPressed: () {}),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: cartItemCount > 0 
        ? ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16).copyWith(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest.withValues(alpha: 0.7),
                  boxShadow: [
                    BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.06), offset: const Offset(0, -16), blurRadius: 32),
                  ]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$cartItemCount Item${cartItemCount > 1 ? 's' : ''} Added', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                        Text('₹${cartTotal.toStringAsFixed(2)}', style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
                      ],
                    ),
                    InkWell(
                      onTap: () => context.push('/cart'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4)),
                          ]
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Go to Cart', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ) 
        : const SizedBox.shrink(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 80, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 350,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Hero(
                            tag: 'product-${product.id}',
                            child: CachedNetworkImage(
                              imageUrl: product.imagePath,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 200),
                              memCacheWidth: 800,
                              placeholder: (context, url) => Container(
                                color: AppColors.surfaceContainerLow,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (product.isOrganic)
                          Positioned(
                            top: 16, left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryFixed,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: const Text('ORGANIC', style: TextStyle(color: AppColors.onSecondaryFixed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                          )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Product Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.brand != null)
                          Text(product.brand!.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 1.0)),
                        const SizedBox(height: 4),
                        Text(product.name, style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.onSurface, height: 1.1, letterSpacing: -0.5)),
                        
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                Icon(Icons.star, color: Colors.amber, size: 18),
                                Icon(Icons.star_half, color: Colors.amber, size: 18),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text('(${product.reviewCount} reviews)', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('₹${product.price.toInt()}', style: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.onSurface)),
                            const SizedBox(width: 12),
                            if (product.originalPrice != null)
                              Text('₹${product.originalPrice!.toInt()}', style: const TextStyle(fontSize: 18, color: AppColors.onSurfaceVariant, decoration: TextDecoration.lineThrough)),
                            const SizedBox(width: 12),
                            if (product.discountPercentage != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(6)),
                                child: Text('-${product.discountPercentage}% OFF', style: const TextStyle(color: AppColors.onErrorContainer, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                          ],
                        ),

                        if (product.cashback != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                                border: Border.all(color: AppColors.secondaryContainer.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.account_balance_wallet, color: AppColors.secondary, size: 18),
                                  const SizedBox(width: 8),
                                  Text('Get ₹${product.cashback} cashback', style: const TextStyle(color: AppColors.onSecondaryContainer, fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quantity & Cart Action
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  if (localCount.value > 1) localCount.value--;
                                },
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.remove, color: AppColors.primaryContainer),
                                ),
                              ),
                              Container(
                                width: 40,
                                alignment: Alignment.center,
                                child: Text('${localCount.value}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              InkWell(
                                onTap: () => localCount.value++,
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.add, color: AppColors.primaryContainer),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              for(int i = 0; i < localCount.value; i++) {
                                ref.read(cartProvider.notifier).addProduct(product);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Added ${localCount.value} to cart!'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(milliseconds: 1000),
                              ));
                              localCount.value = 1; // Reset local
                            },
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: AppColors.secondary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 8)),
                                ]
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Add to Cart', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Combo Offers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Frequently Bought Together', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                        const Text('Add All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      children: [
                        _ComboBundleCard(
                          title: 'Morning Essentials Bundle',
                          price: '₹185',
                          saving: 'Save 15%',
                          images: const [
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuDA4VVm9BKHl6b3j7KiWTVMJ9XDHDbMm--YCGE_2XKtZq0st7dMftm7V4T5ykO-OnGyi7BeZGITKrv0aFu17OgpHshe5qxDIwH-sHzfZMLItR0iEIukegZZzqiw2jjSHj-5rTCNW5JcU72xopdXK1HT20fPbxvxVvqk6TFrnivSpRv_NNZScOzHYfMp3mp5tgwJk1SmUD4_lsORCTuvehRu9NveQ6HWGM3p_LoR5NL1eJckoGAUdLs6QXX78hOpx004LAy9HbEvqDWT',
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuCZy67B_H2-L8jWCorBq6f1EuJu7RTnhr_LVb6eYb2MX_R2kPfgoPCavTQNOU4RK9UhmjjhEoQnB4-kdtblQwYfotZ3QG8O8aOzew93Ddm33p9FeOx0KxBG3y1FoOgKwL8lufUbxI1hA_QN9V4NygRRDL2_u4j_NQGj28zsmVRyWaOMxo66b_16jCIxjapzOxXzvd2mgudfldJrg2ahz-0bdWtCLl-ude0JrJA8LLqoxiP8piSjjnN_2NjVFDvxBLIRET7o7pddReMO',
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuAkGlf4yWr7TA5ChQW-z3h6Z5En77Hc6jPwiVVXF2DHJhP7myfumAFd4m0-bWeXwGKz2lCj6_TdajYfis0o7H1BVZckmRFZG1PZRNwXPcFqj2xBg3E5p2rfaN8y9s-vwwGOAVhGSP_XCZQXB5NyvYc1mhshhAZbSFOn4LRROwwt5bF_yTnsyP2kCnaaLkXa1zmzVdiXyT5uc2aCPdvIgqRYzzwv1ilgR8eeIjLeSsgRbJoXYZIXIESOkSb-ER4n3hn5QFjkbtHB-BuY',
                          ]
                        ),
                        const SizedBox(width: 16),
                        _ComboBundleCard(
                          title: "Dessert Maker's Pack",
                          price: '₹95',
                          saving: 'Save 10%',
                          images: const [
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuA5jgtTc_Xxq2rnmA2k4_VbjV52jDHYkiZjr_bxgteXdVJlvTBkW0SnoRtRkFLzcvQy5WGOIQSn5DxAkOEEN-NOjBf_cojC2PYGQi78jaJSQuPahL8lTHS-vIsJjTaCap8qRfpdmElXrQfEHTvdPTcPbVhvpOfvtYP-0wMot0qUzldmYDXANbXiIpd3v1pJ42dEmI5YxZ6GK6v99jtyY9Q9N1cvNRhtBjqAW3gZJcmzsxhe3Htwz-eyhni6s-dKb0OYS-0cgFFvyhB8',
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuBYWD7HRM2wbCF0TWwPHxTGEezKs1Y5PA2UWftTYeV67bi4QgPHxUcBSKMuvP1Y6QCgrw8c-ZMtVky3Pc_X8Rcd9gNzDWku6jA9lHB3YH2cVu6llpLmSlCts73rtfiFbnpa4VDXzpVKNM4Q1bIbF42_43ux81FNYfE03Ajx4kzlTifjxOdte8juzI1G_YJEhQ2dMcj6B01YKxYuRxn87N6SoR84HJyObuxFTRHzv_47YbBShBsWS2LwhlwFMW4Z512S-EH9cz9QVH8m'
                          ]
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Accordions (Details)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                            iconColor: AppColors.primary,
                            collapsedIconColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceContainerLow,
                            collapsedBackgroundColor: AppColors.surfaceContainerLow,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            initiallyExpanded: true,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text(product.description ?? '', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: const Text('Nutritional Info', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                            iconColor: AppColors.primary,
                            collapsedIconColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceContainerLow,
                            collapsedBackgroundColor: AppColors.surfaceContainerLow,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            children: const [],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: const Text('Storage & Care', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                            iconColor: AppColors.primary,
                            collapsedIconColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceContainerLow,
                            collapsedBackgroundColor: AppColors.surfaceContainerLow,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            children: const [],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Recommendations
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('You may also like', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onSurface)),
                        const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 210,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      children: const [
                        _MiniProductCard(name: 'Golden Pineapple', price: '₹80', imgUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA_vF68JdDs5cgE2BNSgtij6NeGSSO9l8H56Y21813vSZ8g-J9BtkvoxUIOo4GSc_FSW1Wtni_UdDEdnlzv5WV051aZKlvY1MxtyxwOynkVWuSN-ps8NP72Z449WP_K8wlYmu2OCr40wViy6sF0GwAjV61HZ8vQyyQE9xXP5CmkjEIg3QPXtJBpCfPIo1KiJ5LB9adbmN2smWMolZ18SW5Uv-VIN5ioJXFOmKR5KXmexj4x79B1PEZdHpNA4Q1fGVvRW2TD9CalV9Jk'),
                        SizedBox(width: 16),
                         _MiniProductCard(name: 'Wild Blueberries', price: '₹190', imgUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuByhpGzFXWCz8GGs6N4XYD76hKCEohmOb0Pesw7HUmt-S3egRsxQbLLCcwM0x0wp23vUsIyit4-DZ0OkSckeh9aIYHDo0hM8IbP_uz4JUje3mFeStqqbaYAypYNLFR0KhGTMst9hleTCtHCxmQtR-XMpSTPSZcFDZcwdbET7sYohadGJoapXBq78k7lRcuYEiFbjXiW_HeQ5MgIOv2XqM9eCJW0LtL8wbk7HfpiHtT3k-1pgXXAqUFKadgrWVYf8__y2U6ggnbiyABp'),
                        SizedBox(width: 16),
                         _MiniProductCard(name: 'Fuji Apples', price: '₹120', imgUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAhojInL6ivGSm4iEQsM8vPCgc36Bi69DWRCTmqRYEc8jO1RzGWppKFHheJaTSpL6fyDQYVMEz6ikaF153gXrzTwxgsqexrbquFfgNWn_f3HaDbw_9HugYc0xTzK2PPlWGjjqOvcABxehfY_YpfedcfmdVgVs6d7NrAnzz-t2Zadflhg5gSPurMZtLyiYBcQ6hCVUnpgPvQMqWVLk7y5XzOQhyxJCeFTCkjM0XWuqpxO5_QhRUmbYhsK_aMVITg7aMML7g19OqyvUkQ'),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          )
        ],
      )
    );
  }
}

class _ComboBundleCard extends StatelessWidget {
  final String title;
  final String price;
  final String saving;
  final List<String> images;

  const _ComboBundleCard({required this.title, required this.price, required this.saving, required this.images});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -16, bottom: -16,
            child: Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: images.map((img) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    width: 48, height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.1))),
                    child: ClipRRect(borderRadius: BorderRadius.circular(6), child: CachedNetworkImage(imageUrl: img, fit: BoxFit.cover)),
                  ),
                )).toList(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                      Text(saving, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondary)),
                    ],
                  ),
                  Text(price, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.onSurface))
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String imgUrl;

  const _MiniProductCard({required this.name, required this.price, required this.imgUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140, height: 130,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2))
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imgUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                memCacheWidth: 300,
                placeholder: (_, _) => Container(color: AppColors.surfaceContainerLow),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
