import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'widgets/animated_bottom_nav.dart';
import '../cart/providers/cart_provider.dart';
import '../../shared/widgets/cart_toast_bar.dart';

class MainShell extends HookConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the cart badge count from the provider
    final cartItemCount = ref.watch(cartItemCountProvider);

    // Map the current branch index to the tab ID in the bottom nav
    String currentTab;
    switch (navigationShell.currentIndex) {
      case 0:
        currentTab = 'home';
        break;
      case 1:
        currentTab = 'category';
        break;
      case 2:
        currentTab = 'orders';
        break;
      default:
        currentTab = 'home';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // The current branch
          navigationShell,
          
          // Floating Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SwiftmartBottomNav(
              currentTab: currentTab,
              cartBadgeCount: cartItemCount,
              onTabSelected: (tab) {
                if (tab == 'home') {
                  navigationShell.goBranch(0, initialLocation: navigationShell.currentIndex == 0);
                } else if (tab == 'category') {
                  navigationShell.goBranch(1, initialLocation: navigationShell.currentIndex == 1);
                } else if (tab == 'orders') {
                  navigationShell.goBranch(2, initialLocation: navigationShell.currentIndex == 2);
                } else if (tab == 'cart') {
                  context.push('/cart');
                }
              },
            ),
          ),

          // Global floating cart toast — sits above nav bar
          const CartToastBar(),
        ],
      ),
    );
  }
}
