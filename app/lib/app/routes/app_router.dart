import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/go_router_refresh_stream.dart';

import '../../features/home/home_screen.dart';
import '../../features/products/category_screen.dart';
import '../../features/products/browse_categories_screen.dart';
import '../../features/products/product_detail_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/orders/checkout_screen.dart';
import '../../features/orders/mock_payment_screen.dart';
import '../../features/orders/order_success_screen.dart';
import '../../features/orders/order_tracking_screen.dart';
import '../../features/orders/order_history_screen.dart';
import '../../features/products/search_screen.dart';
import '../../features/profile/profile_screen.dart';
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
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      // Fallback for root
      GoRoute(path: '/', redirect: (context, state) => '/home'),
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
        path: '/product/:productId',
        name: 'productDetail',
        builder: (context, state) {
          final id = state.pathParameters['productId']!;
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
        path: '/mock-payment',
        name: 'mockPayment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return MockPaymentScreen(
            orderId: extra['order_id']?.toString() ?? '',
            total: (extra['total'] as num?)?.toDouble() ?? 0.0,
            paymentMethod: extra['payment_method']?.toString() ?? 'upi',
          );
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
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
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final orderId = extra?['order_id']?.toString();
          return OrderSuccessScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/order-tracking',
        name: 'orderTracking',
        builder: (context, state) => const OrderTrackingScreen(),
      ),
      GoRoute(
        path: '/order-history',
        name: 'orderHistory',
        builder: (context, state) => const OrderHistoryScreen(userId: ''),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
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
