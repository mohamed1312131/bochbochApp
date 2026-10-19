import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_input.dart';
import '../../domain/stock_inputs.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_quantity_stepper.dart';
import '../widgets/stock_sheet_product_row.dart';

/// Restock sheet — FLUTTER_SPEC §7.1.
///
/// Records a positive stock movement with its unit cost. Returns
/// `true` when the restock is confirmed and the controller succeeds;
/// `null` / `false` if dismissed.
Future<bool?> showRestockSheet({
  required BuildContext context,
  required String variantId,
  required String productName,
  required String variantSubtitle,
  required int currentStock,
  required int currentWacMillimes,
  int? thumbnailColor,
}) {
  return showDidoBottomSheet<bool>(
    context: context,
    title: 'Restocker',
    child: _RestockSheetBody(
      variantId: variantId,
      productName: productName,
      variantSubtitle: variantSubtitle,
      currentStock: currentStock,
      currentWacMillimes: currentWacMillimes,
      thumbnailColor: thumbnailColor,
    ),
  );
}

class _RestockSheetBody extends ConsumerStatefulWidget {
  const _RestockSheetBody({
    required this.variantId,
    required this.productName,
    required this.variantSubtitle,
    required this.currentStock,
    required this.currentWacMillimes,
    this.thumbnailColor,
  });

  final String variantId;
  final String productName;
  final String variantSubtitle;
  final int currentStock;
  final int currentWacMillimes;
  final int? thumbnailColor;

  @override
  ConsumerState<_RestockSheetBody> createState() => _RestockSheetBodyState();
}

class _RestockSheetBodyState extends ConsumerState<_RestockSheetBody> {
  final TextEditingController quantityCtrl = TextEditingController(text: '10');
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController supplierCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    quantityCtrl.dispose();
    priceCtrl.dispose();
    supplierCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  String _wacHelperText() {
    final qty = int.tryParse(quantityCtrl.text);
    final priceTnd = double.tryParse(priceCtrl.text.replaceAll(',', '.'));
    if (qty == null || qty <= 0 || priceTnd == null || priceTnd <= 0) {
      return 'Saisis la quantité et le prix pour voir le calcul';
    }
    final unitCostMillimes = (priceTnd * 1000).round();
    final totalUnits = widget.currentStock + qty;
    final newWac = totalUnits == 0
        ? unitCostMillimes
        : ((widget.currentStock * widget.currentWacMillimes) +
                (qty * unitCostMillimes)) ~/
            totalUnits;
    return 'Coût moyen actuel : ${_formatTnd(widget.currentWacMillimes)} TND. '
        'Après ce restock : ${_formatTnd(newWac)} TND';
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(quantityCtrl.text);
    if (quantity == null || quantity <= 0) {
      setState(() => _errorMessage = 'Quantité requise');
      return;
    }
    final priceTnd = double.tryParse(priceCtrl.text.replaceAll(',', '.'));
    if (priceTnd == null || priceTnd <= 0) {
      setState(() => _errorMessage = "Prix d'achat requis");
      return;
    }
    final unitCostMillimes = (priceTnd * 1000).round();
    final idempotencyKey = _newIdempotencyKey();

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final input = RestockInput(
        variantId: widget.variantId,
        quantity: quantity,
        unitCost: unitCostMillimes,
        idempotencyKey: idempotencyKey,
        supplierName:
            supplierCtrl.text.trim().isEmpty ? null : supplierCtrl.text.trim(),
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      await ref.read(restockControllerProvider.notifier).submit(input);
      HapticFeedback.lightImpact();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _errorMessage = 'Erreur. Réessaye.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final labelStyle = context.typography.label.copyWith(color: c.fg3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StockSheetProductRow(
          productName: widget.productName,
          subtitle: widget.variantSubtitle,
          thumbnailColor:
              widget.thumbnailColor != null ? Color(widget.thumbnailColor!) : null,
        ),
        const SizedBox(height: 16),
        Text('QUANTITÉ REÇUE', style: labelStyle),
        const SizedBox(height: 8),
        StockQuantityStepper(
          value: int.tryParse(quantityCtrl.text) ?? 1,
          min: 1,
          onChanged: (v) => setState(() => quantityCtrl.text = v.toString()),
        ),
        const SizedBox(height: 16),
        DidoInput(
          controller: priceCtrl,
          label: "PRIX D'ACHAT UNITAIRE",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffixText: 'TND',
          hintText: '45',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        Text(
          _wacHelperText(),
          style: context.typography.caption.copyWith(color: c.fg3),
        ),
        const SizedBox(height: 16),
        DidoInput(
          controller: supplierCtrl,
          label: 'FOURNISSEUR',
          labelOptional: true,
          hintText: 'Nom du fournisseur',
        ),
        const SizedBox(height: 16),
        DidoInput(
          controller: notesCtrl,
          label: 'NOTES',
          labelOptional: true,
          hintText: 'Détails…',
        ),
        const SizedBox(height: 4),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: context.typography.bodySmall.copyWith(color: c.redFg),
          ),
          const SizedBox(height: 8),
        ] else
          const SizedBox(height: 16),
        DidoButton.primary(
          label: 'Confirmer le restock',
          loading: _submitting,
          fullWidth: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}

String _formatTnd(int millimes) {
  final tnd = millimes / 1000;
  var s = tnd.toStringAsFixed(3);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s;
}

String _newIdempotencyKey() =>
    '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(0x7FFFFFFF)}';
