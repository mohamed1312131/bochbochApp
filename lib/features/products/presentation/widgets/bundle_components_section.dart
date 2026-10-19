import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_scale_tap.dart';
import '../../../stock/presentation/providers/stock_provider.dart';
import '../../../stock/presentation/widgets/stock_quantity_stepper.dart';
import '../sheets/bundle_component_picker_sheet.dart';
import 'bundle_component_draft.dart';

/// Reusable bundle composition UI shared by add-product and
/// edit-product screens.
///
/// Single source of truth: the widget owns its mutable
/// `_components` list. `initialComponents` is read once in
/// `initState`; subsequent updates from the parent are ignored
/// (no `didUpdateWidget` reaction). Every mutation fires
/// [onChanged] with a fresh list copy so the parent can read
/// the latest state on save without keeping a parallel field.
class BundleComponentsSection extends ConsumerStatefulWidget {
  const BundleComponentsSection({
    super.key,
    required this.initialComponents,
    required this.onChanged,
  });

  final List<BundleComponentDraft> initialComponents;
  final ValueChanged<List<BundleComponentDraft>> onChanged;

  @override
  ConsumerState<BundleComponentsSection> createState() =>
      _BundleComponentsSectionState();
}

class _BundleComponentsSectionState
    extends ConsumerState<BundleComponentsSection> {
  late final List<BundleComponentDraft> _components =
      List.from(widget.initialComponents);

  void _emit() => widget.onChanged(List.from(_components));

  Future<void> _add() async {
    final draft = await showBundleComponentPickerSheet(
      context: context,
      ref: ref,
    );
    if (draft != null) {
      setState(() => _components.add(draft));
      _emit();
    }
  }

  void _setQty(int index, int v) {
    setState(() => _components[index].qtyPerBundle = v);
    _emit();
  }

  void _remove(int index) {
    setState(() => _components.removeAt(index));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'COMPOSANTS',
          style: context.typography.label
              .copyWith(color: c.fg3, letterSpacing: 1.2),
        ),
        SizedBox(height: context.spacing.space2),
        for (var i = 0; i < _components.length; i++) ...[
          _BundleComponentCard(
            component: _components[i],
            onQtyChanged: (v) => _setQty(i, v),
            onRemove: () => _remove(i),
          ),
          if (i < _components.length - 1)
            SizedBox(height: context.spacing.space2),
        ],
        if (_components.isNotEmpty) SizedBox(height: context.spacing.space3),
        DidoButton.secondary(
          label: 'Ajouter composant',
          icon: Icons.add_rounded,
          fullWidth: true,
          onPressed: _add,
        ),
        SizedBox(height: context.spacing.space6),
        Text(
          'DISPONIBILITÉ DU PACK',
          style: context.typography.label
              .copyWith(color: c.fg3, letterSpacing: 1.2),
        ),
        SizedBox(height: context.spacing.space2),
        _BundleAvailability(components: _components),
        SizedBox(height: context.spacing.space2),
        Text(
          'Calculée à partir de tes composants. Le pack est disponible '
          'tant que tous ses composants le sont.',
          style: context.typography.caption.copyWith(color: c.fg3),
        ),
      ],
    );
  }
}

class _BundleComponentCard extends StatelessWidget {
  const _BundleComponentCard({
    required this.component,
    required this.onQtyChanged,
    required this.onRemove,
  });

  final BundleComponentDraft component;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1, width: 1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: component.thumbnailColor != null
                  ? Color(component.thumbnailColor!)
                  : c.surface3,
              borderRadius:
                  BorderRadius.circular(context.radius.radiusTile),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typography.bodyMd.copyWith(color: c.fg1),
                ),
                const SizedBox(height: 2),
                Text(
                  component.sku,
                  style:
                      context.typography.caption.copyWith(color: c.fg3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StockQuantityStepper(
            value: component.qtyPerBundle,
            min: 1,
            max: 99,
            compact: true,
            onChanged: onQtyChanged,
          ),
          const SizedBox(width: 8),
          DidoScaleTap(
            onTap: onRemove,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius:
                    BorderRadius.circular(context.radius.radiusInput),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.close_rounded, size: 16, color: c.fg2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live computed availability: `min(state.available ÷ qtyPerBundle)`
/// across components. Watches `stockStateProvider` per component so
/// updates flow when restock/adjust mutations land.
class _BundleAvailability extends ConsumerWidget {
  const _BundleAvailability({required this.components});

  final List<BundleComponentDraft> components;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    if (components.isEmpty) {
      return Text(
        '0',
        style: context.typography.tileNum.copyWith(color: c.coralFg),
      );
    }
    var minAvail = 1 << 30;
    for (final comp in components) {
      final state =
          ref.watch(stockStateProvider(comp.variantId)).valueOrNull;
      final available = state == null
          ? 0
          : (state.onHand > 0 ||
                  state.committedOrders.isNotEmpty ||
                  state.backordered > 0)
              ? state.available
              : 0;
      final per = comp.qtyPerBundle == 0 ? 1 : comp.qtyPerBundle;
      final candidate = available ~/ per;
      if (candidate < minAvail) minAvail = candidate;
    }
    final value = minAvail < (1 << 30) ? minAvail : 0;
    return Text(
      '$value',
      style: context.typography.tileNum
          .copyWith(color: value > 0 ? c.fg1 : c.coralFg),
    );
  }
}
