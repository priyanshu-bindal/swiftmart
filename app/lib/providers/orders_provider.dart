import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';

final ordersProvider = AsyncNotifierProvider<OrdersNotifier, List<Order>>(() {
  return OrdersNotifier();
});

class OrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    final repo = ref.watch(orderRepositoryProvider);
    return await repo.fetchOrders();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(orderRepositoryProvider);
      final orders = await repo.fetchOrders();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
