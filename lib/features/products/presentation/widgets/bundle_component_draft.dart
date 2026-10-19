/// Form-state DTO for a bundle component as the user composes it
/// in the add-product / edit-product screens.
///
/// NOT persisted — distinct from `BundleComponent` in
/// `lib/features/stock/domain/stock_models.dart` which is the
/// API/persistence shape. This draft lives only in widget state
/// while the seller picks variants and tunes per-bundle quantities.
class BundleComponentDraft {
  BundleComponentDraft({
    required this.variantId,
    required this.productName,
    required this.sku,
    required this.componentCost,
    this.qtyPerBundle = 1,
    this.thumbnailColor,
  });

  final String variantId;
  final String productName;
  final String sku;
  final int componentCost;
  int qtyPerBundle;
  final int? thumbnailColor;
}
