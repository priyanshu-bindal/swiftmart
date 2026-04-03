import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:dio/dio.dart';
import '../models/order_model.dart';
// import '../repositories/dio_order_repository.dart';

// Provides the Dio instance
// final dioProvider = Provider((ref) {
//   // Use 10.0.2.2 for Android emulators to access host's localhost
//   final baseUrl = Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
//   return Dio(BaseOptions(
//     baseUrl: baseUrl,
//     connectTimeout: const Duration(seconds: 5),
//   ));
// });

// Provides the Repository
// final orderRepositoryProvider = Provider((ref) {
//   return DioOrderRepository(ref.watch(dioProvider));
// });

// StateNotifier for fetching order history
class OrderHistoryNotifier extends AsyncNotifier<List<OrderModel>> {
  @override
  Future<List<OrderModel>> build() async {
    final auth = ref.watch(authProvider);
    final userId = auth.user?.id;
    
    if (userId == null) {
      return [];
    }

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: \$e');
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
