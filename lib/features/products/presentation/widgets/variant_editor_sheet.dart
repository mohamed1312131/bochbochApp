import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_input.dart';
import '../../../../shared/widgets/dido_scale_tap.dart';
import 'variant_draft.dart';

/// Bottom sheet for composing a single product variant.
///
/// Returns the new/edited [VariantDraft] when the seller hits
/// "Enregistrer". Returns `null` when dismissed without saving.
///
/// Pass [initial] to edit an existing draft; the sheet copies its
/// fields into local controllers so cancelling preserves the original.
Future<VariantDraft?> showVariantEditorSheet({
  required BuildContext context,
  VariantDraft? initial,
}) {
  return showDidoBottomSheet<VariantDraft>(
    context: context,
    title: initial == null ? 'Nouvelle variante' : 'Modifier la variante',
    child: _VariantEditorBody(initial: initial),
  );
}

class _VariantEditorBody extends StatefulWidget {
  const _VariantEditorBody({this.initial});
  final VariantDraft? initial;

  @override
  State<_VariantEditorBody> createState() => _VariantEditorBodyState();
}

class _AttrControllers {
  _AttrControllers({String name = '', String value = ''})
      : name = TextEditingController(text: name),
        value = TextEditingController(text: value);
  final TextEditingController name;
  final TextEditingController value;
  void dispose() {
    name.dispose();
    value.dispose();
  }
}

class _VariantEditorBodyState extends State<_VariantEditorBody> {
  final List<_AttrControllers> _attrs = [];
  final _stockController = TextEditingController();
  final _costController = TextEditingController();
  final _sellController = TextEditingController();
  bool _showPriceOverrides = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      for (final a in init.attributes) {
        _attrs.add(_AttrControllers(name: a.name, value: a.value));
      }
      _stockController.text = init.stockQuantity.toString();
      if (init.costPriceMillimes != null) {
        _showPriceOverrides = true;
        _costController.text =
            MillimesFormatter.toTnd(init.costPriceMillimes!).toString();
      }
      if (init.sellPriceMillimes != null) {
        _showPriceOverrides = true;
        _sellController.text =
            MillimesFormatter.toTnd(init.sellPriceMillimes!).toString();
      }
    }
    // Always start with at least one empty attribute row so the user
    // doesn't tap "Ajouter" to begin composing.
    if (_attrs.isEmpty) {
      _attrs.add(_AttrControllers());
    }
    for (final a in _attrs) {
      a.name.addListener(_rebuild);
      a.value.addListener(_rebuild);
    }
    _stockController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    for (final a in _attrs) {
      a.dispose();
    }
    _stockController.dispose();
    _costController.dispose();
    _sellController.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_attrs.isEmpty) return false;
    if (!_attrs.every(
      (a) => a.name.text.trim().isNotEmpty && a.value.text.trim().isNotEmpty,
    )) {
      return false;
    }
    final stock = int.tryParse(_stockController.text.trim());
    if (stock == null || stock < 0) return false;
    return true;
  }

  void _addAttr() {
    setState(() {
      final ctrl = _AttrControllers();
      ctrl.name.addListener(_rebuild);
      ctrl.value.addListener(_rebuild);
      _attrs.add(ctrl);
    });
  }

  void _removeAttr(int index) {
    setState(() {
      _attrs[index].dispose();
      _attrs.removeAt(index);
    });
  }

  int? _parseTndOptional(String raw) {
    final cleaned = raw.replaceAll(',', '.').trim();
    if (cleaned.isEmpty) return null;
    final tnd = double.tryParse(cleaned);
    if (tnd == null || tnd <= 0) return null;
    return MillimesFormatter.toMillimes(tnd);
  }

  void _save() {
    final attrs = [
      for (final a in _attrs)
        VariantAttributeDraft(
          name: a.name.text.trim(),
          value: a.value.text.trim(),
        ),
    ];
    final draft = VariantDraft(
      attributes: attrs,
      stockQuantity: int.tryParse(_stockController.text.trim()) ?? 0,
      costPriceMillimes:
          _showPriceOverrides ? _parseTndOptional(_costController.text) : null,
      sellPriceMillimes:
          _showPriceOverrides ? _parseTndOptional(_sellController.text) : null,
    );
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.space4,
        context.spacing.space2,
        context.spacing.space4,
        context.spacing.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.brandTealTint08,
              borderRadius:
                  BorderRadius.circular(context.radius.radiusInput),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: c.brandTeal),
                SizedBox(width: context.spacing.space2),
                Expanded(
                  child: Text(
                    "Cette fenêtre décrit UNE seule variante. "
                    "Si tu en as plusieurs (Rouge M, Rouge XL, Noir M…), "
                    "enregistre celle-ci puis tape « Ajouter une variante » "
                    "pour la suivante.",
                    style: context.typography.caption.copyWith(
                      color: c.brandTeal,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.spacing.space3),
          _VariantPreview(attrs: _attrs, stock: _stockController.text),
          SizedBox(height: context.spacing.space4),
          Text(
            'CARACTÉRISTIQUES',
            style: context.typography.label
                .copyWith(color: c.fg3, letterSpacing: 1.2),
          ),
          SizedBox(height: context.spacing.space2),
          Padding(
            padding: const EdgeInsets.only(right: 48), // align with remove btn
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Type',
                    style: context.typography.caption.copyWith(color: c.fg3),
                  ),
                ),
                SizedBox(width: context.spacing.space2),
                Expanded(
                  child: Text(
                    'Valeur',
                    style: context.typography.caption.copyWith(color: c.fg3),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.spacing.space1),
          for (var i = 0; i < _attrs.length; i++) ...[
            _AttrRow(
              // Identity-based key so Flutter reconciles rows by the
              // backing controller pair rather than by list position.
              // Without this, removing an attribute shifts the
              // remaining controllers into different slots and the
              // associated TextField state (focus node, internal
              // selection key) can land in two places in the same
              // frame — triggering a duplicate-GlobalKey assertion.
              key: ObjectKey(_attrs[i]),
              index: i,
              name: _attrs[i].name,
              value: _attrs[i].value,
              onRemove: _attrs.length > 1 ? () => _removeAttr(i) : null,
            ),
            if (i < _attrs.length - 1) SizedBox(height: context.spacing.space2),
          ],
          SizedBox(height: context.spacing.space2),
          DidoScaleTap(
            onTap: _addAttr,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: c.brandTealTint08,
                borderRadius:
                    BorderRadius.circular(context.radius.radiusInput),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: c.brandTeal),
                  SizedBox(width: context.spacing.space2),
                  Text(
                    'Ajouter une caractéristique',
                    style: context.typography.button
                        .copyWith(color: c.brandTeal),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: context.spacing.space5),
          Text(
            'STOCK DE CETTE VARIANTE',
            style: context.typography.label
                .copyWith(color: c.fg3, letterSpacing: 1.2),
          ),
          SizedBox(height: context.spacing.space2),
          DidoInput(
            controller: _stockController,
            hintText: '10',
            suffixText: 'unités',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          SizedBox(height: context.spacing.space5),
          _PriceOverridesToggle(
            expanded: _showPriceOverrides,
            onTap: () =>
                setState(() => _showPriceOverrides = !_showPriceOverrides),
          ),
          if (_showPriceOverrides) ...[
            SizedBox(height: context.spacing.space3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DidoInput(
                    controller: _costController,
                    label: "Coût (optionnel)",
                    hintText: '45',
                    suffixText: 'TND',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                  ),
                ),
                SizedBox(width: context.spacing.space3),
                Expanded(
                  child: DidoInput(
                    controller: _sellController,
                    label: "Vente (optionnel)",
                    hintText: '90',
                    suffixText: 'TND',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.spacing.space2),
            Text(
              "Laisse vide pour utiliser les prix du produit.",
              style: context.typography.caption.copyWith(color: c.fg3),
            ),
          ],
          SizedBox(height: context.spacing.space5),
          DidoButton.primary(
            label: 'Enregistrer',
            onPressed: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }
}

class _AttrRow extends StatelessWidget {
  const _AttrRow({
    super.key,
    required this.index,
    required this.name,
    required this.value,
    required this.onRemove,
  });
  final int index;
  final TextEditingController name;
  final TextEditingController value;
  final VoidCallback? onRemove;

  // Rotated examples so each successive row reads as a distinct
  // characteristic rather than a duplicate of the first.
  static const List<List<String>> _hintPairs = [
    ['Couleur', 'Rouge'],
    ['Taille', 'M'],
    ['Matière', 'Coton'],
    ['Format', 'Standard'],
    ['Style', 'Classique'],
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pair = _hintPairs[index % _hintPairs.length];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DidoInput(
            controller: name,
            hintText: 'ex. ${pair[0]}',
          ),
        ),
        SizedBox(width: context.spacing.space2),
        Expanded(
          child: DidoInput(
            controller: value,
            hintText: 'ex. ${pair[1]}',
          ),
        ),
        if (onRemove != null) ...[
          SizedBox(width: context.spacing.space2),
          DidoScaleTap(
            onTap: onRemove,
            child: Container(
              width: 40,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius:
                    BorderRadius.circular(context.radius.radiusInput),
              ),
              child: Icon(Icons.close_rounded, size: 18, color: c.fg2),
            ),
          ),
        ],
      ],
    );
  }
}

/// Live preview of the variant being composed. Reads the controllers
/// directly (parent rebuilds on every keystroke via _rebuild listeners)
/// and renders a single-line summary so the seller can verify what
/// "Enregistrer" will actually save.
class _VariantPreview extends StatelessWidget {
  const _VariantPreview({required this.attrs, required this.stock});
  final List<_AttrControllers> attrs;
  final String stock;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final values = [
      for (final a in attrs)
        if (a.value.text.trim().isNotEmpty) a.value.text.trim(),
    ];
    final stockTrim = stock.trim();
    final hasContent = values.isNotEmpty || stockTrim.isNotEmpty;
    final label = values.isEmpty ? '—' : values.join(' · ');
    final stockLabel = stockTrim.isEmpty ? '—' : '$stockTrim en stock';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusInput),
      ),
      child: Row(
        children: [
          Text(
            'Cette variante :',
            style: context.typography.caption.copyWith(color: c.fg3),
          ),
          SizedBox(width: context.spacing.space2),
          Expanded(
            child: Text(
              hasContent ? '$label · $stockLabel' : 'rien encore',
              style: context.typography.body.copyWith(
                color: hasContent ? c.fg1 : c.fg3,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceOverridesToggle extends StatelessWidget {
  const _PriceOverridesToggle({required this.expanded, required this.onTap});
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DidoScaleTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: c.brandTeal,
            ),
            SizedBox(width: context.spacing.space1),
            Text(
              'Personnaliser les prix de cette variante',
              style: context.typography.button.copyWith(color: c.brandTeal),
            ),
          ],
        ),
      ),
    );
  }
}
