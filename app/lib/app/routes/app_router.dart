import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/go_router_refresh_stream.dart';

import '../../features/home/home_screen.dart';
import '../../features/home/main_shell.dart';
import '../../features/products/category_screen.dart';
import '../../features/products/browse_categories_screen.dart';
import '../../features/products/product_detail_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/orders/checkout_screen.dart';
import '../../features/orders/order_success_screen.dart';
import '../../features/orders/order_tracking_screen.dart';
import '../../features/orders/order_history_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/products/search_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/addresses_screen.dart';
import '../../features/profile/add_address_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/deals/flash_deals_screen.dart';
import '../../features/offers/coupons_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final isAuthenticated =
          Supabase.instance.client.auth.currentSession != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
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

      // ── Root redirect ─────────────────────────────────────────────────────
      GoRoute(path: '/', redirect: (context, state) => '/home'),

      // ── Main Shell (Home, Categories, Orders) ─────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/browse_categories',
                name: 'browseCategories',
                builder: (context, state) => const BrowseCategoriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/order-history',
                name: 'orderHistory',
                builder: (context, state) => const OrderHistoryScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Products / Categories ─────────────────────────────────────────────
      // /CategoryModel/:categoryId?name=CategoryName
      GoRoute(
        path: '/CategoryModel/:categoryId',
        name: 'CategoryModel',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          final categoryName = (state.extra as String?) ?? state.uri.queryParameters['name'] ?? 'Category';
          return CategoryScreen(
            categoryId: categoryId,
            categoryName: categoryName,
          );
        },
      ),
      GoRoute(
        path: '/ProductModel/:productId',
        name: 'productDetail',
        builder: (context, state) {
          final id = state.pathParameters['productId']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),

      // ── Cart & Checkout ───────────────────────────────────────────────────
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

      // ── Orders ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/order-confirm/:orderId',
        name: 'orderConfirm',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'];
          return OrderSuccessScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/order-success',
        name: 'orderSuccess',
        redirect: (context, state) {
          // Guard: if navigated to directly without a valid order_id, go home.
          final extra = state.extra as Map<String, dynamic>?;
          final orderId = extra?['order_id']?.toString();
          if (orderId == null || orderId.isEmpty) return '/home';
          return null;
        },
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final orderId = extra?['order_id']?.toString();
          return OrderSuccessScreen(orderId: orderId);
        },
      ),


      GoRoute(
        path: '/order-track/:orderId',
        name: 'orderTracking',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderTrackingScreen(orderId: orderId);
        },
      ),
      // Legacy route without path param (keep for backward compat)
      GoRoute(
        path: '/order-tracking',
        name: 'orderTrackingLegacy',
        builder: (context, state) => const OrderTrackingScreen(orderId: ''),
      ),
      GoRoute(
        path: '/order-detail/:orderId',
        name: 'orderDetail',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return OrderDetailScreen(orderId: orderId);
        },
      ),

      // ── Profile ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/addresses',
        name: 'addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/add-address',
        name: 'addAddress',
        builder: (context, state) => const AddAddressScreen(),
      ),

      // ── Deals & Offers ────────────────────────────────────────────────────
      GoRoute(
        path: '/flash-deals',
        name: 'flashDeals',
        builder: (context, state) => const FlashDealsScreen(),
      ),
      GoRoute(
        path: '/coupons',
        name: 'coupons',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fromCart = extra?['fromCart'] as bool? ?? false;
          return CouponsScreen(fromCart: fromCart);
        },
      ),
    ],
  );
});
