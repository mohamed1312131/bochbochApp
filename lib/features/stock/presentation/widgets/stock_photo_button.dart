import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_scale_tap.dart';

/// Photo attach button — FLUTTER_SPEC §6.17.
///
/// Two states:
/// - Empty: dashed-border 44h pill with icon + label.
/// - Attached: 80×80 thumbnail with a close-button overlay calling
///   [onRemove].
class StockPhotoButton extends StatelessWidget {
  const StockPhotoButton({
    super.key,
    required this.onTap,
    this.label = '+ Ajouter photo',
    this.hasPhoto = false,
    this.photoUrl,
    this.onRemove,
  });

  final VoidCallback onTap;
  final String label;
  final bool hasPhoto;
  final String? photoUrl;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (!hasPhoto) {
      return DidoScaleTap(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: c.border1,
            radius: context.radius.radiusInput,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_outlined, size: 16, color: c.fg1),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: context.typography.smallMd.copyWith(color: c.fg1),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Photo-attached state
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.surface3,
              borderRadius:
                  BorderRadius.circular(context.radius.radiusInput),
            ),
            clipBehavior: Clip.antiAlias,
            child: photoUrl == null
                ? null
                : Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: c.surface3),
                  ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRemove,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0x99000000),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Renders a dashed rounded-rectangle border around the child bounds.
/// 4px dash, 4px gap. All four sides drawn from a single Path so the
/// pattern wraps the corners cleanly.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  static const _dashWidth = 4.0;
  static const _dashGap = 4.0;
  static const _strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
