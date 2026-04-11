/// Represents a combo deal configuration attached to a product.
/// If productA has a comboDeal, buying both productA + linkedProductId
/// together gives both at [comboPrice] each (or a combined comboPrice split).
class ComboDeal {
  /// The other product that must be in the cart to activate the deal.
  final String linkedProductId;

  /// The discounted price THIS product charges when the combo is active.
  final double thisItemComboPrice;

  /// Human-readable label, e.g. "Milk + Bread Combo"
  final String? label;

  const ComboDeal({
    required this.linkedProductId,
    required this.thisItemComboPrice,
    this.label,
  });

  factory ComboDeal.fromJson(Map<String, dynamic> json) {
    return ComboDeal(
      linkedProductId: json['linked_product_id'] as String,
      thisItemComboPrice:
          (json['this_item_combo_price'] as num?)?.toDouble() ?? 0.0,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'linked_product_id': linkedProductId,
        'this_item_combo_price': thisItemComboPrice,
        'label': label,
      };
}
