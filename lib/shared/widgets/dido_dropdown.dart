import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import 'dido_bottom_sheet.dart';
import 'dido_scale_tap.dart';

/// One option in a [DidoDropdown].
class DidoDropdownItem<T> {
  const DidoDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}

/// Tappable dropdown styled like [DidoInput], with a [showDidoBottomSheet]
/// list picker. Replaces ad-hoc `DropdownButtonFormField` usages so the
/// dropdown matches the rest of the design system (surface1 + border1
/// + radiusInput shell, NBSP-bound French labels, full-screen-readable
/// list).
class DidoDropdown<T> extends StatelessWidget {
  const DidoDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.label,
    this.sheetTitle,
  });

  final T? value;
  final List<DidoDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? label;

  /// Sheet title; falls back to [label] then `'Choisir'`.
  final String? sheetTitle;

  String? _labelFor(T? v) {
    if (v == null) return null;
    for (final item in items) {
      if (item.value == v) return item.label;
    }
    return null;
  }

  Future<void> _openSheet(BuildContext context) async {
    final c = context.colors;
    final selected = await showDidoBottomSheet<T>(
      context: context,
      title: sheetTitle ?? label ?? 'Choisir',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            DidoScaleTap(
              onTap: () => Navigator.of(context).pop(items[i].value),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      items[i].label,
                      style: context.typography.body.copyWith(color: c.fg1),
                    ),
                    if (items[i].subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        items[i].subtitle!,
                        style:
                            context.typography.caption.copyWith(color: c.fg3),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (i < items.length - 1)
              Container(height: 1, color: c.border1),
          ],
        ],
      ),
    );
    if (selected != null) onChanged?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final currentLabel = _labelFor(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: context.typography.label.copyWith(color: c.fg3),
          ),
          const SizedBox(height: 8),
        ],
        DidoScaleTap(
          onTap: onChanged == null ? null : () => _openSheet(context),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface1,
              border: Border.all(color: c.border1, width: 1),
              borderRadius:
                  BorderRadius.circular(context.radius.radiusInput),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    currentLabel ?? hint ?? 'Sélectionner',
                    style: context.typography.body.copyWith(
                      color: currentLabel == null ? c.fg3 : c.fg1,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: c.fg3,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
