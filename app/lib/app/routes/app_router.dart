import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/home/home_screen.dart';
import '../../features/products/category_screen.dart';
import '../../features/products/browse_categories_screen.dart';
import '../../features/products/product_detail_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/orders/checkout_screen.dart';
import '../../features/orders/order_success_screen.dart';
import '../../screens/order_tracking_screen.dart';
import '../../screens/order_history_screen.dart';
import '../../features/products/search_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to auth state changes and refresh router
  final authListenable = ValueNotifier<bool>(false);
  ref.listen<AuthState>(authProvider, (_, next) {
    authListenable.value = !authListenable.value;
    if (next.isAuthenticated && !next.isLoading) {
      ref.read(cartProvider.notifier).loadFromRemote();
    }
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // Still initializing — no redirect yet
      if (authState.isLoading) return null;

      final isLoggedIn = authState.isAuthenticated;
      final isOnAuthPage =
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup');

      if (!isLoggedIn && !isOnAuthPage) return '/login';
      if (isLoggedIn && isOnAuthPage) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/category',
        name: 'category',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final categoryName = extra?['name'] as String? ?? 'Category';
          return CategoryScreen(categoryName: categoryName);
        },
      ),
      GoRoute(
        path: '/browse_categories',
        name: 'browseCategories',
        builder: (context, state) => const BrowseCategoriesScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        name: 'productDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/order-success',
        name: 'orderSuccess',
        builder: (context, state) => const OrderSuccessScreen(),
      ),
      GoRoute(
        path: '/order-tracking',
        name: 'orderTracking',
        builder: (context, state) => const OrderTrackingScreen(),
      ),
      GoRoute(
        path: '/order-history',
        name: 'orderHistory',
        builder: (context, state) {
          final userId = ref.read(authProvider).user?.uid ?? '';
          return OrderHistoryScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
