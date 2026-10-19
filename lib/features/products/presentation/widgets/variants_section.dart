import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_scale_tap.dart';
import 'variant_draft.dart';
import 'variant_editor_sheet.dart';

/// Editable list of [VariantDraft]s — used on the add-product screen
/// when the seller has flipped on "Ce produit a des variantes".
///
/// The widget owns its mutable list; every mutation re-emits a fresh
/// copy via [onChanged] so the parent can read the latest state on
/// save without keeping a parallel field. Same pattern as
/// `BundleComponentsSection`.
class VariantsSection extends StatefulWidget {
  const VariantsSection({
    super.key,
    required this.initialVariants,
    required this.onChanged,
  });

  final List<VariantDraft> initialVariants;
  final ValueChanged<List<VariantDraft>> onChanged;

  @override
  State<VariantsSection> createState() => _VariantsSectionState();
}

class _VariantsSectionState extends State<VariantsSection> {
  late final List<VariantDraft> _variants = List.from(widget.initialVariants);

  void _emit() => widget.onChanged(List.from(_variants));

  Future<void> _add() async {
    final draft = await showVariantEditorSheet(context: context);
    if (draft != null) {
      setState(() => _variants.add(draft));
      _emit();
    }
  }

  Future<void> _edit(int index) async {
    final draft = await showVariantEditorSheet(
      context: context,
      initial: _variants[index],
    );
    if (draft != null) {
      setState(() => _variants[index] = draft);
      _emit();
    }
  }

  void _remove(int index) {
    setState(() => _variants.removeAt(index));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'VARIANTES',
          style: context.typography.label
              .copyWith(color: c.fg3, letterSpacing: 1.2),
        ),
        SizedBox(height: context.spacing.space2),
        if (_variants.isEmpty)
          _EmptyState(onAdd: _add)
        else ...[
          for (var i = 0; i < _variants.length; i++) ...[
            _VariantCard(
              key: ObjectKey(_variants[i]),
              draft: _variants[i],
              onEdit: () => _edit(i),
              onRemove: () => _remove(i),
            ),
            if (i < _variants.length - 1)
              SizedBox(height: context.spacing.space2),
          ],
          SizedBox(height: context.spacing.space3),
          _AddVariantTile(onTap: _add),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DidoScaleTap(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1, width: 1, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.brandTealTint08,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, size: 20, color: c.brandTeal),
            ),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajouter une variante',
                    style: context.typography.body
                        .copyWith(color: c.fg1, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Couleur, taille, format…',
                    style: context.typography.caption.copyWith(color: c.fg3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddVariantTile extends StatelessWidget {
  const _AddVariantTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DidoScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.brandTealTint08,
          borderRadius: BorderRadius.circular(context.radius.radiusInput),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: c.brandTeal),
            SizedBox(width: context.spacing.space2),
            Text(
              'Ajouter une variante',
              style: context.typography.button.copyWith(color: c.brandTeal),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    super.key,
    required this.draft,
    required this.onEdit,
    required this.onRemove,
  });
  final VariantDraft draft;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final priceLabel = _priceLabel(context, draft);
    return DidoScaleTap(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1, width: 1),
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.attributeLabel,
                    style: context.typography.body
                        .copyWith(color: c.fg1, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${draft.stockQuantity} en stock'
                    '${priceLabel != null ? ' · $priceLabel' : ''}',
                    style: context.typography.caption.copyWith(color: c.fg3),
                  ),
                ],
              ),
            ),
            DidoScaleTap(
              onTap: onRemove,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: c.fg3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _priceLabel(BuildContext context, VariantDraft d) {
    if (d.costPriceMillimes == null && d.sellPriceMillimes == null) {
      return null;
    }
    final parts = <String>[];
    if (d.sellPriceMillimes != null) {
      parts.add('${MillimesFormatter.toTnd(d.sellPriceMillimes!).toStringAsFixed(0)} TND');
    }
    return parts.join(' ');
  }
}
