import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../orders/presentation/sheets/product_picker_sheet.dart';
import '../providers/product_provider.dart';
import '../widgets/bundle_component_draft.dart';

/// Bundle component picker — chunk 8b-2 task 6.
///
/// Adapter over [showProductPickerSheet] (orders flow) so the
/// add-product / edit-product bundle-mode UI can reuse the same
/// search → variant-list flow without duplicating any of it.
///
/// On a successful pick, fetches the full product to fill the
/// component's `sku` (which `OrderItemDraft` doesn't carry) and
/// returns a [BundleComponentDraft] with `qtyPerBundle: 1`. Caller
/// adjusts the qty via the stepper inside the bundle component
/// card. Returns `null` if dismissed or if the post-pick fetch
/// fails — caller should treat null as "user backed out".
Future<BundleComponentDraft?> showBundleComponentPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final picked = await showProductPickerSheet(context);
  if (picked == null) return null;
  try {
    final full =
        await ref.read(productRepositoryProvider).getProduct(picked.productId);
    final variant = full.variants.firstWhere(
      (v) => v.id == picked.variantId,
      orElse: () => full.variants.first,
    );
    return BundleComponentDraft(
      variantId: picked.variantId,
      productName: picked.productName,
      sku: variant.sku,
      componentCost: picked.unitCost,
      qtyPerBundle: 1,
    );
  } catch (_) {
    return null;
  }
}
