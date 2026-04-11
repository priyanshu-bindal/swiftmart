import 'product_model.dart';

class CartItemModel {
  final String id;
  final String productId;
  final int quantity;
  final ProductModel? product;

  /// If non-null, this item is part of a combo with the specified partner product ID.
  /// The number of "active" combo pairs = min(this.quantity, partner.quantity).
  final String? comboPartnerId;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.quantity,
    this.product,
    this.comboPartnerId,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'] as Map<String, dynamic>)
          : null,
      // comboPartnerId is only tracked in client-side state, not in DB
    );
  }

  CartItemModel copyWith({
    String? id,
    String? productId,
    int? quantity,
    ProductModel? product,
    String? comboPartnerId,
    bool clearCombo = false,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      product: product ?? this.product,
      comboPartnerId: clearCombo ? null : (comboPartnerId ?? this.comboPartnerId),
    );
  }

  /// Effective price per unit considering combo pairing.
  /// [partnerQty] = quantity of the partner item currently in cart.
  double effectiveUnitPrice(int partnerQty) {
    final comboPrice = product?.comboDeal?.thisItemComboPrice;
    if (comboPartnerId == null || comboPrice == null) {
      return product?.salePrice ?? 0.0;
    }
    // Only the minimum of both quantities get the combo price
    final comboPairs = partnerQty.clamp(0, quantity);
    if (comboPairs <= 0) return product?.salePrice ?? 0.0;
    // Blended price: comboPairs at combo rate, rest at regular
    final regularPairs = quantity - comboPairs;
    final total = (comboPairs * comboPrice) +
        (regularPairs * (product?.salePrice ?? 0.0));
    return total / quantity;
  }

  /// Total price taking combo into account.
  double totalPrice({int partnerQty = 0}) =>
      effectiveUnitPrice(partnerQty) * quantity;
}
