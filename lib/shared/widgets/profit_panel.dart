import 'package:flutter/material.dart';

import '../../core/theme/app_theme_extension.dart';
import '../../core/utils/millimes_formatter.dart';
import '../../features/orders/domain/order_models.dart';

/// Margin tone — semantic color tier for profit display.
/// Single source of truth (NEW_FEATURES_SPEC §1.4):
///   - marginPercent >= 20            → success
///   - marginPercent >= 10  &&  < 20  → warning
///   - marginPercent < 10  OR  netProfit < 0  → error
enum ProfitTone { success, warning, error }

ProfitTone profitToneFor({required int netProfit, required double marginPercent}) {
  if (netProfit < 0) return ProfitTone.error;
  if (marginPercent >= 20) return ProfitTone.success;
  if (marginPercent >= 10) return ProfitTone.warning;
  return ProfitTone.error;
}

/// Per-order profit panel — collapsible card showing the breakdown.
/// Renders a single-row collapsed view (dot + label + amount + chevron)
/// that expands into an animated body of itemized cost lines.
class ProfitPanel extends StatefulWidget {
  const ProfitPanel({
    super.key,
    required this.data,
    this.startExpanded = false,
  });

  final ProfitBreakdown data;
  final bool startExpanded;

  @override
  State<ProfitPanel> createState() => _ProfitPanelState();
}

class _ProfitPanelState extends State<ProfitPanel> {
  late bool _expanded = widget.startExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = profitToneFor(
      netProfit: widget.data.netProfit,
      marginPercent: widget.data.marginPercent,
    );
    final toneFg = _toneFg(c, tone);
    final toneSolid = _toneSolid(c, tone);

    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CollapsedRow(
            label: 'Bénéfice net',
            value: _formatSigned(widget.data.netProfit),
            toneFg: toneFg,
            toneSolid: toneSolid,
            expanded: _expanded,
            onTap: _toggle,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _ExpandedBody(data: widget.data, tone: tone)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ── Collapsed row ─────────────────────────────────────────
class _CollapsedRow extends StatelessWidget {
  const _CollapsedRow({
    required this.label,
    required this.value,
    required this.toneFg,
    required this.toneSolid,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color toneFg;
  final Color toneSolid;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.radius.radiusCard),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: toneSolid,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: context.spacing.space2),
            Expanded(
              child: Text(
                label,
                style: context.typography.body.copyWith(color: c.fg2),
              ),
            ),
            Text(
              value,
              style: context.typography.bodyMdNum.copyWith(
                color: toneFg,
                fontSize: 18,
                height: 22 / 18,
              ),
            ),
            SizedBox(width: context.spacing.space2),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c.surface2,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: c.fg2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expanded body ─────────────────────────────────────────
class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({required this.data, required this.tone});
  final ProfitBreakdown data;
  final ProfitTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final toneFg = _toneFg(c, tone);
    final toneBg = _toneBg(c, tone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: c.border1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            children: [
              _Line(
                label: 'Prix de vente',
                value: MillimesFormatter.format(data.salePrice),
                valueColor: c.fg1,
              ),
              _Line(
                label: 'Coût produit',
                value: '−${MillimesFormatter.format(data.productCost)}',
                valueColor: c.fg2,
              ),
              _Line(
                label: 'Frais de livraison',
                value: '−${MillimesFormatter.format(data.shippingCost)}',
                valueColor: c.fg2,
              ),
              _Line(
                label: 'Remise appliquée',
                value:
                    '−${MillimesFormatter.format(data.discountApplied)}',
                valueColor: c.fg2,
              ),
              if (data.hasExchange)
                _Line(
                  label: 'Frais d\'échange',
                  // Signed: positive cost prefixed '−', negative shows '+'.
                  value: data.exchangeCost >= 0
                      ? '−${MillimesFormatter.format(data.exchangeCost)}'
                      : '+${MillimesFormatter.format(-data.exchangeCost)}',
                  valueColor: c.fg2,
                ),
              SizedBox(height: context.spacing.space2),
              Container(height: 1, color: c.border1),
              SizedBox(height: context.spacing.space2),
              _NetLine(
                label: 'Bénéfice net',
                value: _formatSigned(data.netProfit),
                marginPercent: data.marginPercent,
                toneFg: toneFg,
                toneBg: toneBg,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.space1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.typography.body.copyWith(color: c.fg2),
            ),
          ),
          Text(
            value,
            style: context.typography.bodyMdNum.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _NetLine extends StatelessWidget {
  const _NetLine({
    required this.label,
    required this.value,
    required this.marginPercent,
    required this.toneFg,
    required this.toneBg,
  });
  final String label;
  final String value;
  final double marginPercent;
  final Color toneFg;
  final Color toneBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing.space1),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  label,
                  style: context.typography.h4.copyWith(color: toneFg),
                ),
                SizedBox(width: context.spacing.space2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: toneBg,
                    borderRadius: BorderRadius.circular(
                        context.radius.radiusChip),
                  ),
                  child: Text(
                    '${_fmtMargin(marginPercent)}% marge',
                    style: context.typography.tabPill.copyWith(color: toneFg),
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: context.typography.numberLg.copyWith(
              color: toneFg,
              fontSize: 20,
              height: 24 / 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tone resolvers ────────────────────────────────────────
Color _toneFg(dynamic c, ProfitTone tone) => switch (tone) {
      ProfitTone.success => c.greenFg,
      ProfitTone.warning => c.coralFg,
      ProfitTone.error => c.redFg,
    };

Color _toneBg(dynamic c, ProfitTone tone) => switch (tone) {
      ProfitTone.success => c.greenTint12,
      ProfitTone.warning => c.coralTint12,
      ProfitTone.error => c.redTint12,
    };

Color _toneSolid(dynamic c, ProfitTone tone) => switch (tone) {
      ProfitTone.success => c.greenFg,
      ProfitTone.warning => c.coral,
      ProfitTone.error => c.red,
    };

// ── Helpers ───────────────────────────────────────────────
String _formatSigned(int millimes) {
  if (millimes >= 0) return MillimesFormatter.format(millimes);
  return '−${MillimesFormatter.format(-millimes)}';
}

String _fmtMargin(double margin) {
  // 1 decimal, French comma — matches MillimesFormatter's locale.
  return margin.toStringAsFixed(1).replaceAll('.', ',');
}
