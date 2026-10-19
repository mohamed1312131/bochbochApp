import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../domain/exchange_models.dart';
import 'exchange_confirm_screen.dart';

/// Screen 2 of the exchange flow — capture optional costs.
///
/// All three fields are optional. The "Passer" header action skips
/// straight to confirmation with all costs cleared. "Continuer"
/// pushes confirmation with the entered values.
class ExchangeCostsScreen extends StatefulWidget {
  const ExchangeCostsScreen({super.key, required this.draft});
  final ExchangeDraft draft;

  @override
  State<ExchangeCostsScreen> createState() => _ExchangeCostsScreenState();
}

class _ExchangeCostsScreenState extends State<ExchangeCostsScreen> {
  final _returnCtrl = TextEditingController();
  final _reshipCtrl = TextEditingController();
  final _diffCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill if the user already entered values and bounced back.
    final d = widget.draft;
    if (d.returnShippingCost != null) {
      _returnCtrl.text = MillimesFormatter.toTnd(d.returnShippingCost!)
          .toStringAsFixed(0);
    }
    if (d.redeliveryCost != null) {
      _reshipCtrl.text =
          MillimesFormatter.toTnd(d.redeliveryCost!).toStringAsFixed(0);
    }
    if (d.priceDifference != null) {
      _diffCtrl.text =
          MillimesFormatter.toTnd(d.priceDifference!).toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _returnCtrl.dispose();
    _reshipCtrl.dispose();
    _diffCtrl.dispose();
    super.dispose();
  }

  // Convert "X" or "X.Y" tnd input → millimes int. Returns null on
  // empty / unparseable. Validation against the 200_000-millime
  // backend cap happens server-side and surfaces as a 400.
  int? _parseTnd(String input, {bool signed = false}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final cleaned = trimmed.replaceAll(',', '.');
    final v = double.tryParse(cleaned);
    if (v == null) return null;
    if (!signed && v < 0) return null;
    return MillimesFormatter.toMillimes(v);
  }

  void _onContinue() {
    final updated = widget.draft.copyWith(
      returnShippingCost: _parseTnd(_returnCtrl.text),
      redeliveryCost: _parseTnd(_reshipCtrl.text),
      priceDifference: _parseTnd(_diffCtrl.text, signed: true),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ExchangeConfirmScreen(draft: updated, costsSkipped: false),
      ),
    );
  }

  void _onSkip() {
    final cleared = widget.draft.clearCosts();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ExchangeConfirmScreen(draft: cleared, costsSkipped: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final orderLabel = widget.draft.orderNumber ?? widget.draft.orderId;
    return Scaffold(
      backgroundColor: c.surface1,
      appBar: AppBar(
        title: const Text('Coûts de l\'échange'),
        actions: [
          TextButton(
            onPressed: _onSkip,
            child: Text(
              'Passer',
              style: context.typography.button.copyWith(color: c.fg2),
            ),
          ),
          SizedBox(width: context.spacing.space2),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.spacing.space4,
                context.spacing.space3,
                context.spacing.space4,
                context.spacing.space4,
              ),
              children: [
                Text(
                  'Tous les champs sont optionnels. Les montants saisis seront ajoutés au panneau bénéfice de la commande #$orderLabel.',
                  style: context.typography.body.copyWith(color: c.fg2),
                ),
                SizedBox(height: context.spacing.space5),
                _CostField(
                  controller: _returnCtrl,
                  label: 'Frais de retour',
                  hint: 'Coût de récupération de l\'article retourné.',
                ),
                SizedBox(height: context.spacing.space4),
                _CostField(
                  controller: _reshipCtrl,
                  label: 'Frais de réexpédition',
                  hint: 'Coût d\'envoi du nouvel article à la cliente.',
                ),
                SizedBox(height: context.spacing.space4),
                _CostField(
                  controller: _diffCtrl,
                  label: 'Différence de prix',
                  hint:
                      'Positif si le nouvel article est plus cher, négatif si moins cher.',
                  signed: true,
                  placeholder: '± 0',
                ),
                SizedBox(height: context.spacing.space5),
                _InfoBanner(
                  text:
                      'Ces frais apparaîtront dans le détail bénéfice de la commande originale.',
                ),
              ],
            ),
          ),
          _Footer(onContinue: _onContinue),
        ],
      ),
    );
  }
}

// ── CostField ─────────────────────────────────────────────
class _CostField extends StatelessWidget {
  const _CostField({
    required this.controller,
    required this.label,
    required this.hint,
    this.signed = false,
    this.placeholder = '0',
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool signed;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: context.typography.label.copyWith(color: c.fg1),
            ),
            SizedBox(width: context.spacing.space1),
            Text(
              '· optionnel',
              style: context.typography.label.copyWith(color: c.fg3),
            ),
          ],
        ),
        SizedBox(height: context.spacing.space2),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: c.surface0,
            border: Border.all(color: c.border1),
            borderRadius: BorderRadius.circular(context.radius.radiusInput),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                    signed: signed,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      signed ? RegExp(r'[0-9\-.,]') : RegExp(r'[0-9.,]'),
                    ),
                  ],
                  textAlignVertical: TextAlignVertical.center,
                  style: context.typography.input.copyWith(color: c.fg1),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14),
                    isDense: true,
                    hintStyle:
                        context.typography.input.copyWith(color: c.fg4),
                  ),
                ),
              ),
              Container(width: 1, height: 28, color: c.border1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'TND',
                  style: context.typography.bodyMd.copyWith(color: c.fg3),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.spacing.space2),
        Text(
          hint,
          style: context.typography.caption.copyWith(color: c.fg3),
        ),
      ],
    );
  }
}

// ── Info banner (teal tint) ───────────────────────────────
class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.brandTealTint08,
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: c.brandTeal),
          SizedBox(width: context.spacing.space2),
          Expanded(
            child: Text(
              text,
              style: context.typography.bodySmall.copyWith(color: c.brandTeal),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer({required this.onContinue});
  final VoidCallback onContinue;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          context.spacing.space4,
          context.spacing.space3,
          context.spacing.space4,
          context.spacing.space4,
        ),
        decoration: BoxDecoration(
          color: c.surface0,
          border: Border(top: BorderSide(color: c.border1)),
        ),
        child: DidoButton.primary(
          label: 'Continuer',
          onPressed: onContinue,
        ),
      ),
    );
  }
}
