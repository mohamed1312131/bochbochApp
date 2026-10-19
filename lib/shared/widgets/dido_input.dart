import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme_extension.dart';

/// Input field — UX_DESIGN_SYSTEM_V1.1.md §3.7.
///
/// Single source for the form-field pattern previously inlined as
/// `_AuthField` / `_CardField` across auth / onboarding / orders /
/// products / customers screens.
///
/// The container shell handles the visual treatment (background,
/// border, focus ring, error border) so the inner [TextField] can
/// stay borderless. Focus state is driven by an internal [FocusNode]
/// when the caller doesn't supply one.
class DidoInput extends StatefulWidget {
  const DidoInput({
    super.key,
    required this.controller,
    this.label,
    this.labelOptional = false,
    this.hintText,
    this.suffixText,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.errorText,
    this.helperText,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? label;
  final bool labelOptional;
  final String? hintText;
  final String? suffixText;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final bool enabled;
  final String? errorText;
  final String? helperText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<DidoInput> createState() => _DidoInputState();
}

class _DidoInputState extends State<DidoInput> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final f = _focusNode.hasFocus;
    if (f != _focused) setState(() => _focused = f);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasError = widget.errorText != null;
    final isMultiline = widget.maxLines > 1 || (widget.minLines ?? 1) > 1;

    final radius = BorderRadius.circular(context.radius.radiusInput);

    final Color bg;
    final Color borderColor;
    final double borderWidth;
    final List<BoxShadow> shadow;
    if (hasError) {
      bg = c.surface2;
      borderColor = c.red;
      borderWidth = 1.5;
      shadow = const <BoxShadow>[];
    } else if (_focused) {
      bg = c.surface1;
      borderColor = c.brandTeal;
      borderWidth = 1;
      shadow = <BoxShadow>[
        BoxShadow(
          color: c.brandTealTint16,
          blurRadius: 0,
          spreadRadius: 3,
        ),
      ];
    } else {
      bg = c.surface2;
      borderColor = Colors.transparent;
      borderWidth = 1;
      shadow = const <BoxShadow>[];
    }

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      height: isMultiline ? null : 48,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor, width: borderWidth),
        borderRadius: radius,
        boxShadow: shadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: isMultiline ? Alignment.topLeft : Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (widget.prefixIcon != null) ...[
            Padding(
              padding: EdgeInsets.only(top: isMultiline ? 14 : 0),
              child: Icon(widget.prefixIcon, size: 18, color: c.fg3),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              inputFormatters: widget.inputFormatters,
              onChanged: widget.onChanged,
              onTap: widget.onTap,
              style: context.typography.input.copyWith(color: c.fg1),
              cursorColor: c.fg1,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: isMultiline ? 14 : 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText: widget.hintText,
                hintStyle:
                    context.typography.input.copyWith(color: c.fg3),
              ),
            ),
          ),
          if (widget.suffixText != null) ...[
            const SizedBox(width: 8),
            Padding(
              padding: EdgeInsets.only(top: isMultiline ? 14 : 0),
              child: Text(
                widget.suffixText!,
                style:
                    context.typography.smallMd.copyWith(color: c.fg3),
              ),
            ),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          _Label(
            label: widget.label!,
            optional: widget.labelOptional,
          ),
          const SizedBox(height: 8),
        ],
        container,
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: context.typography.caption.copyWith(color: c.redFg),
          ),
        ] else if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: context.typography.caption.copyWith(color: c.fg3),
          ),
        ],
      ],
    );
  }
}

/// Renders the input label as UPPERCASE primary span plus an optional
/// " · optionnel" suffix in caption typography (no uppercase).
class _Label extends StatelessWidget {
  const _Label({required this.label, required this.optional});

  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spans = <InlineSpan>[
      TextSpan(
        text: label.toUpperCase(),
        style: context.typography.label.copyWith(color: c.fg3),
      ),
      if (optional)
        TextSpan(
          text: ' · optionnel',
          style: context.typography.caption.copyWith(color: c.fg3),
        ),
    ];
    return RichText(text: TextSpan(children: spans));
  }
}
