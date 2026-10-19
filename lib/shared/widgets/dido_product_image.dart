import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays either a bundled demo asset or a production network image.
///
/// The static investor demo stores product photos under `assets/`, while the
/// production API continues to return HTTPS URLs. Keeping that distinction in
/// one widget prevents presentation screens from assuming every URL is remote.
class DidoProductImage extends StatelessWidget {
  const DidoProductImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderBuilder,
    this.errorBuilder,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholderBuilder;
  final WidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _error(context);
    }

    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, _, __) => _error(context),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, _) =>
          placeholderBuilder?.call(context) ?? const SizedBox.shrink(),
      errorWidget: (context, _, __) => _error(context),
    );
  }

  Widget _error(BuildContext context) =>
      errorBuilder?.call(context) ?? const SizedBox.shrink();
}
