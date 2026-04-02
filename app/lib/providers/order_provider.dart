import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/order_model.dart';
import '../repositories/dio_order_repository.dart';

// Provides the Dio instance
final dioProvider = Provider((ref) {
  // Use 10.0.2.2 for Android emulators to access host's localhost
  final baseUrl = Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  return Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 5),
  ));
});

// Provides the Repository
final orderRepositoryProvider = Provider((ref) {
  return DioOrderRepository(ref.watch(dioProvider));
});

// StateNotifier for fetching order history
class OrderHistoryNotifier extends AsyncNotifier<List<OrderModel>> {
  @override
  Future<List<OrderModel>> build() async {
    return []; // initial state, wait for fetch
  }

  Future<void> fetchOrders(String userId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(orderRepositoryProvider);
      final orders = await repo.getUserOrders(userId);
      state = AsyncValue.data(orders);
    } catch (e) {
      // Provide mock data if backend connection fails (so you can view the fully animated UI)
      final mockData = [
        OrderModel(
          id: 'ORD-9824AA',
          userId: userId,
          totalAmount: 18.50,
          deliveryFee: 2.0,
          discountAmount: 0.0,
          status: 'DELIVERED',
          paymentMethod: 'Credit Card',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        OrderModel(
          id: 'ORD-1092XB',
          userId: userId,
          totalAmount: 42.00,
          deliveryFee: 0.0,
          discountAmount: 5.0,
          status: 'OUT_FOR_DELIVERY',
          paymentMethod: 'Apple Pay',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
      state = AsyncValue.data(mockData);
    }
  }
}

final orderHistoryProvider = AsyncNotifierProvider<OrderHistoryNotifier, List<OrderModel>>(() {
  return OrderHistoryNotifier();
});

// Provider for holding current active order context (useful for tracking via Sockets in real-time)
class ActiveOrderNotifier extends Notifier<OrderModel?> {
  @override
  OrderModel? build() => null;

  void setOrder(OrderModel? newOrder) {
    state = newOrder;
  }
}

final activeOrderProvider = NotifierProvider<ActiveOrderNotifier, OrderModel?>(() {
  return ActiveOrderNotifier();
});
