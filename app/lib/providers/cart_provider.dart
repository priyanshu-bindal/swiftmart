import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../repositories/cart_repository.dart';

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  Future<void> loadFromRemote() async {
    try {
      final repo = ref.read(cartRepositoryProvider);
      final remoteItems = await repo.fetchCart();
      state = remoteItems;
    } catch (_) {}
  }

  void _syncItemWithRemote(String productId, int quantity) {
    Future.microtask(() async {
      try {
        final repo = ref.read(cartRepositoryProvider);
        await repo.syncItem(productId, quantity);
      } catch (_) {}
    });
  }

  void addProduct(Product product) {
    final state = this.state;
    final index = state.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      state[index] = state[index].copyWith(quantity: state[index].quantity + 1);
      this.state = [...state];
      _syncItemWithRemote(product.id, state[index].quantity);
    } else {
      final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
      this.state = [
        ...state,
        CartItem(id: '', userId: uid, productId: product.id, product: product),
      ];
      _syncItemWithRemote(product.id, 1);
    }
  }

  void removeProduct(String productId) {
    var state = this.state;
    final index = state.indexWhere((item) => item.product.id == productId);

    if (index != -1) {
      if (state[index].quantity > 1) {
        state[index] = state[index].copyWith(
          quantity: state[index].quantity - 1,
        );
        this.state = [...state];
        _syncItemWithRemote(productId, state[index].quantity);
      } else {
        this.state = state
            .where((item) => item.product.id != productId)
            .toList();
        _syncItemWithRemote(productId, 0);
      }
    }
  }

  void removeProductCompletely(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
    _syncItemWithRemote(productId, 0);
  }

  Future<void> clearCart() async {
    state = [];
    try {
      final repo = ref.read(cartRepositoryProvider);
      await repo.clearCart();
    } catch (_) {}
  }

  double get totalAmount {
    return state.fold(0, (total, item) => total + item.totalPrice);
  }

  int get itemCount {
    return state.fold(0, (count, item) => count + item.quantity);
  }
}
