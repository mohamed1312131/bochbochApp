import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import 'dido_scale_tap.dart';

/// Bottom sheet shell — UX_DESIGN_SYSTEM_V1.1.md §6.1.
///
/// Replaces ad-hoc `showModalBottomSheet` calls scattered across the
/// app. The sheet floats on a scrim, has a 36×4 drag handle, a title +
/// close-button header, and a scrollable body wrapping the supplied
/// child.
///
/// The default modal bottom-sheet animation handles the slide-up and
/// scrim fade — no custom animation is needed.
Future<T?> showDidoBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    barrierColor: context.colors.scrim,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (sheetContext) => _DidoBottomSheetShell(
      title: title,
      child: child,
    ),
  );
}

class _DidoBottomSheetShell extends StatelessWidget {
  const _DidoBottomSheetShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final maxHeight = MediaQuery.of(context).size.height - 24;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: context.shadows.shadowSheet,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border2,
                  borderRadius:
                      BorderRadius.circular(context.radius.radiusFull),
                ),
              ),
            ),
          ),
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.h3.copyWith(color: c.fg1),
                  ),
                ),
                DidoScaleTap(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.surface2,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.close, size: 16, color: c.fg1),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
