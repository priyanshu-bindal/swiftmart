import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// State for the floating cart toast.
class CartToastState {
  final bool visible;
  final String productName;
  final String? productImage;
  final int totalItemsJustAdded;

  const CartToastState({
    required this.visible,
    required this.productName,
    this.productImage,
    required this.totalItemsJustAdded,
  });

  CartToastState copyWith({
    bool? visible,
    String? productName,
    String? productImage,
    int? totalItemsJustAdded,
  }) =>
      CartToastState(
        visible: visible ?? this.visible,
        productName: productName ?? this.productName,
        productImage: productImage ?? this.productImage,
        totalItemsJustAdded: totalItemsJustAdded ?? this.totalItemsJustAdded,
      );

  static const empty = CartToastState(
    visible: false,
    productName: '',
    productImage: null,
    totalItemsJustAdded: 0,
  );
}

class CartToastNotifier extends Notifier<CartToastState> {
  Timer? _dismissTimer;

  @override
  CartToastState build() => CartToastState.empty;

  /// Show (or update) the toast with a new item.
  void show({
    required String productName,
    String? productImage,
  }) {
    _dismissTimer?.cancel();

    final newCount = state.visible ? state.totalItemsJustAdded + 1 : 1;

    state = state.copyWith(
      visible: true,
      productName: productName,
      productImage: productImage,
      totalItemsJustAdded: newCount,
    );

    _dismissTimer = Timer(const Duration(milliseconds: 2800), dismiss);
  }

  /// Hide the toast (slide-down animation is handled by the widget).
  void dismiss() {
    _dismissTimer?.cancel();
    state = state.copyWith(visible: false);

    // Reset count after the slide-out animation finishes (~400ms)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!state.visible) {
        state = CartToastState.empty;
      }
    });
  }
}

final cartToastProvider =
    NotifierProvider<CartToastNotifier, CartToastState>(CartToastNotifier.new);
