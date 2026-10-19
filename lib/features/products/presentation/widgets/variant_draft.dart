/// Form-state DTO for a product variant as the seller composes it
/// in the add-product flow.
///
/// NOT persisted — distinct from `ProductVariant` in
/// `lib/features/products/domain/product_models.dart`, which is the
/// API response shape. This draft lives only in widget state until
/// the seller hits "Enregistrer", at which point the parent maps it
/// to the JSON payload sent to POST /products.
class VariantAttributeDraft {
  VariantAttributeDraft({required this.name, required this.value});
  String name;
  String value;
}

class VariantDraft {
  VariantDraft({
    required this.attributes,
    required this.stockQuantity,
    this.costPriceMillimes,
    this.sellPriceMillimes,
  });

  /// Ordered list of attribute name/value pairs (e.g. Couleur=Rouge,
  /// Taille=M). At least one pair is required for a variant — the
  /// backend rejects empty attribute arrays.
  final List<VariantAttributeDraft> attributes;

  /// Per-variant stock count. Backed by the same OrderItem column the
  /// scalar `initialStock` writes to in the single-variant path.
  int stockQuantity;

  /// Optional per-variant cost override (millimes). When null the
  /// variant inherits the product's baseCostPrice.
  int? costPriceMillimes;

  /// Optional per-variant sell override (millimes). When null the
  /// variant inherits the product's baseSellPrice.
  int? sellPriceMillimes;

  /// Human-readable label for the variant card, e.g. "Rouge · M".
  String get attributeLabel =>
      attributes.map((a) => a.value).where((v) => v.isNotEmpty).join(' · ');

  bool get isValid {
    if (attributes.isEmpty) return false;
    return attributes.every(
      (a) => a.name.trim().isNotEmpty && a.value.trim().isNotEmpty,
    );
  }

  Map<String, dynamic> toJson() => {
        'stockQuantity': stockQuantity,
        if (costPriceMillimes != null) 'costPrice': costPriceMillimes,
        if (sellPriceMillimes != null) 'sellPrice': sellPriceMillimes,
        'attributes': [
          for (final a in attributes)
            {'name': a.name.trim(), 'value': a.value.trim()},
        ],
      };
}
