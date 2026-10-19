import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_toggle.dart';

/// Settings backorder card — FLUTTER_SPEC §6.19.
///
/// Title + subtitle pair on the left, [DidoToggle] on the right.
/// Uses `radiusInput` (8) intentionally per spec — looks tighter
/// than `radiusCard` for in-list settings rows.
class StockSettingsBackorderCard extends StatelessWidget {
  const StockSettingsBackorderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1, width: 1),
        borderRadius:
            BorderRadius.circular(context.radius.radiusInput),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.typography.bodyMd.copyWith(color: c.fg1),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style:
                      context.typography.bodySmall.copyWith(color: c.fg3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DidoToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
