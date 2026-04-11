import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Maps productId -> deal override price (in ₹).
/// Populated when a user adds a product from a flash deal card.
/// Cleared when the item is removed from cart.
class FlashDealPriceNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() => {};

  void setOverride(String productId, double dealPrice) {
    state = {...state, productId: dealPrice};
  }

  void clearOverride(String productId) {
    final updated = Map<String, double>.from(state);
    updated.remove(productId);
    state = updated;
  }

  void clearAll() => state = {};

  double? getPrice(String productId) => state[productId];
}

final flashDealPriceProvider =
    NotifierProvider<FlashDealPriceNotifier, Map<String, double>>(
  FlashDealPriceNotifier.new,
);
