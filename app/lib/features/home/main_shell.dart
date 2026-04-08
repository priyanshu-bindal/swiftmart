import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'widgets/animated_bottom_nav.dart';
import '../cart/providers/cart_provider.dart';
import '../../shared/widgets/cart_toast_bar.dart';
import '../../shared/providers/nav_visibility_provider.dart';

class MainShell extends HookConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItemCount = ref.watch(cartItemCountProvider);
    final isNavVisible = ref.watch(navVisibilityProvider);

    // AnimationController drives the slide up/down of the navbar.
    final animCtrl = useAnimationController(
      duration: const Duration(milliseconds: 250),
      initialValue: 1.0, // 1.0 = fully visible
    );

    // Slide animation: Offset(0, 0) = visible, Offset(0, 1) = fully off-screen below
    final slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(parent: animCtrl, curve: Curves.easeInOut));

    // React to provider changes
    useEffect(() {
      if (isNavVisible) {
        animCtrl.reverse(); // slide up into view  (1 → 0)
      } else {
        animCtrl.forward(); // slide down out of view (0 → 1)
      }
      return null;
    }, [isNavVisible]);

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
      extendBody: true,
      body: Stack(
        children: [
          // The current branch
          navigationShell,

          // Floating Bottom Navigation Bar — slides down when hidden
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: slideAnim,
              child: SwiftmartBottomNav(
                currentTab: currentTab,
                cartBadgeCount: cartItemCount,
                onTabSelected: (tab) {
                  // Tapping the nav always makes it visible again
                  ref.read(navVisibilityProvider.notifier).show();
                  if (tab == 'home') {
                    navigationShell.goBranch(
                        0,
                        initialLocation:
                            navigationShell.currentIndex == 0);
                  } else if (tab == 'category') {
                    navigationShell.goBranch(
                        1,
                        initialLocation:
                            navigationShell.currentIndex == 1);
                  } else if (tab == 'orders') {
                    navigationShell.goBranch(
                        2,
                        initialLocation:
                            navigationShell.currentIndex == 2);
                  } else if (tab == 'cart') {
                    context.push('/cart');
                  }
                },
              ),
            ),
          ),

          // Global floating cart toast — sits above nav bar
          const CartToastBar(),
        ],
      ),
    );
  }
}
