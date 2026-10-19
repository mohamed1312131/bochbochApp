import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_scale_tap.dart';

/// Single reason option in a [StockReasonRadioList]. `value` is the
/// backend-stable enum string (e.g. "broken"), `label` is the
/// localized French copy.
class StockReasonOption {
  const StockReasonOption({required this.value, required this.label});

  final String value;
  final String label;
}

/// Radio-style reason picker — FLUTTER_SPEC §6.6.
///
/// Vertical list of reasons inside a single bordered card.
/// Tap-anywhere-on-row selects the option and fires [onChanged].
/// Caller owns the selection state.
class StockReasonRadioList extends StatelessWidget {
  const StockReasonRadioList({
    super.key,
    required this.reasons,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<StockReasonOption> reasons;
  final String? selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1, width: 1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < reasons.length; i++) ...[
            _ReasonRow(
              option: reasons[i],
              selected: reasons[i].value == selectedValue,
              onTap: () => onChanged(reasons[i].value),
            ),
            if (i != reasons.length - 1)
              Container(height: 1, color: c.border1),
          ],
        ],
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final StockReasonOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DidoScaleTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RadioDot(selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: context.typography.body.copyWith(color: c.fg1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: c.surface1,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? c.fg1 : c.border2,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: c.fg1,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
