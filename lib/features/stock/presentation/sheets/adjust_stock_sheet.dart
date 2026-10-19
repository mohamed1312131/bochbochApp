import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_input.dart';
import '../../../../shared/widgets/dido_segmented.dart';
import '../../domain/stock_enums.dart';
import '../../domain/stock_inputs.dart';
import '../providers/stock_provider.dart';
import '../widgets/stock_photo_button.dart';
import '../widgets/stock_quantity_stepper.dart';
import '../widgets/stock_reason_radio_list.dart';
import '../widgets/stock_sheet_product_row.dart';

/// Stock adjustment sheet — FLUTTER_SPEC §7.2.
Future<bool?> showAdjustStockSheet({
  required BuildContext context,
  required String variantId,
  required String productName,
  required String variantSubtitle,
  required int currentStock,
  int? thumbnailColor,
}) {
  return showDidoBottomSheet<bool>(
    context: context,
    title: 'Ajuster le stock',
    child: _AdjustStockSheetBody(
      variantId: variantId,
      productName: productName,
      variantSubtitle: variantSubtitle,
      currentStock: currentStock,
      thumbnailColor: thumbnailColor,
    ),
  );
}

class _AdjustStockSheetBody extends ConsumerStatefulWidget {
  const _AdjustStockSheetBody({
    required this.variantId,
    required this.productName,
    required this.variantSubtitle,
    required this.currentStock,
    this.thumbnailColor,
  });

  final String variantId;
  final String productName;
  final String variantSubtitle;
  final int currentStock;
  final int? thumbnailColor;

  @override
  ConsumerState<_AdjustStockSheetBody> createState() =>
      _AdjustStockSheetBodyState();
}

class _AdjustStockSheetBodyState extends ConsumerState<_AdjustStockSheetBody> {
  bool _isAddDirection = false;
  final TextEditingController quantityCtrl = TextEditingController(text: '1');
  StockAdjustmentReason _selectedReason = StockAdjustmentReason.damage;
  final TextEditingController notesCtrl = TextEditingController();
  String? _photoUrl;
  bool _uploadingPhoto = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    quantityCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref
          .read(stockRepositoryProvider)
          .uploadAdjustmentPhoto(file.path);
      if (mounted) {
        setState(() {
          _photoUrl = url;
          _uploadingPhoto = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
          _errorMessage = "Erreur d'envoi de la photo. Réessaye.";
        });
      }
    }
  }

  Future<void> _submit() async {
    final quantity = int.tryParse(quantityCtrl.text);
    if (quantity == null || quantity <= 0) {
      setState(() => _errorMessage = 'Quantité requise');
      return;
    }
    final qtyDelta = _isAddDirection ? quantity : -quantity;
    final idempotencyKey = _newIdempotencyKey();

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      // Backend takes the absolute target (newOnHandQuantity), not a
      // delta. Read freshest state at submit-time and compute. If
      // committed orders already exceed the target the backend rejects
      // with a French message — surfaced via the catch below.
      final state =
          await ref.read(stockStateProvider(widget.variantId).future);
      final newOnHand = state.onHand + qtyDelta;
      if (newOnHand < 0) {
        setState(() {
          _submitting = false;
          _errorMessage = 'Stock négatif impossible.';
        });
        return;
      }

      final input = AdjustmentInput(
        variantId: widget.variantId,
        newOnHandQuantity: newOnHand,
        reason: _selectedReason,
        idempotencyKey: idempotencyKey,
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
        photoUrl: _photoUrl,
      );
      await ref.read(adjustmentControllerProvider.notifier).submit(input);
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
    final reasons = StockAdjustmentReason.values
        .map((r) => StockReasonOption(value: r.apiValue, label: r.label))
        .toList();
    final quantity = int.tryParse(quantityCtrl.text) ?? 0;
    final showBackorderWarning =
        !_isAddDirection && quantity > widget.currentStock;

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
        Text("TYPE D'AJUSTEMENT", style: labelStyle),
        const SizedBox(height: 8),
        DidoSegmented(
          segments: const ['Retirer', 'Ajouter'],
          activeIndex: _isAddDirection ? 1 : 0,
          onSegmentTap: (i) => setState(() => _isAddDirection = i == 1),
        ),
        const SizedBox(height: 16),
        Text('QUANTITÉ', style: labelStyle),
        const SizedBox(height: 8),
        StockQuantityStepper(
          value: int.tryParse(quantityCtrl.text) ?? 1,
          min: 1,
          onChanged: (v) => setState(() => quantityCtrl.text = v.toString()),
        ),
        const SizedBox(height: 16),
        Text('POURQUOI ?', style: labelStyle),
        const SizedBox(height: 8),
        StockReasonRadioList(
          reasons: reasons,
          selectedValue: _selectedReason.apiValue,
          onChanged: (v) => setState(
              () => _selectedReason = StockAdjustmentReason.fromApi(v)),
        ),
        const SizedBox(height: 16),
        DidoInput(
          controller: notesCtrl,
          label: 'NOTES',
          labelOptional: true,
          hintText: 'Détails…',
        ),
        const SizedBox(height: 16),
        StockPhotoButton(
          hasPhoto: _photoUrl != null,
          photoUrl: _photoUrl,
          onTap: (_photoUrl == null && !_uploadingPhoto)
              ? _pickAndUploadPhoto
              : () {},
          onRemove:
              _photoUrl != null ? () => setState(() => _photoUrl = null) : null,
        ),
        if (_uploadingPhoto) ...[
          const SizedBox(height: 6),
          Text(
            'Envoi en cours…',
            style: context.typography.caption.copyWith(color: c.fg3),
          ),
        ],
        if (showBackorderWarning) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.coralTint12,
              borderRadius: BorderRadius.circular(context.radius.radiusCard),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: c.coral, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Tu n'as que ${widget.currentStock} en stock. Active "
                    "'accepter backorders' dans le produit ou réduis la "
                    "quantité.",
                    style:
                        context.typography.bodySmall.copyWith(color: c.coralFg),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          label: 'Confirmer',
          loading: _submitting,
          fullWidth: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}

String _newIdempotencyKey() =>
    '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(0x7FFFFFFF)}';
