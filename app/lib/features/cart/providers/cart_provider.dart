import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../models/product.dart';
import '../../../core/local_storage/database_helper.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    _loadFromDb();
    return [];
  }

  Future<void> _loadFromDb() async {
    try {
      final items = await DatabaseHelper.instance.getCart();
      state = items;
    } catch (e) {
      // Ignored for now if db fails to load
    }
  }

  void _syncDb() {
    DatabaseHelper.instance.saveCart(state);
  }

  void addProduct(Product product) {
    final state = this.state;
    final index = state.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      state[index].quantity++;
      this.state = [...state];
    } else {
      this.state = [...state, CartItem(product: product)];
    }
    _syncDb();
  }

  void removeProduct(String productId) {
    var state = this.state;
    final index = state.indexWhere((item) => item.product.id == productId);

    if (index != -1) {
      if (state[index].quantity > 1) {
        state[index].quantity--;
        this.state = [...state];
      } else {
        this.state = state.where((item) => item.product.id != productId).toList();
      }
      _syncDb();
    }
  }

  void removeProductCompletely(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
    _syncDb();
  }

  void clearCart() {
    state = [];
    DatabaseHelper.instance.clearCart();
  }

  double get totalAmount {
    return state.fold(0, (total, item) => total + item.totalPrice);
  }

  int get itemCount {
    return state.fold(0, (count, item) => count + item.quantity);
  }
}
