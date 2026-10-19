import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_toggle_row.dart';
import '../../domain/customer_address_models.dart';
import '../providers/customer_addresses_provider.dart';

const List<String> _tunisiaGovernorates = [
  'Tunis', 'Ariana', 'Ben Arous', 'Manouba',
  'Nabeul', 'Zaghouan', 'Bizerte', 'Béja',
  'Jendouba', 'Kef', 'Siliana', 'Sousse',
  'Monastir', 'Mahdia', 'Sfax', 'Kairouan',
  'Kasserine', 'Sidi Bouzid', 'Gabes', 'Mednine',
  'Tataouine', 'Gafsa', 'Tozeur', 'Kebili',
];

/// FLUTTER_SPEC §3.7 — sheet for creating or editing an address.
/// Pass [existing] to edit; omit to create.
Future<void> showAddressSheet({
  required BuildContext context,
  required String customerId,
  CustomerAddress? existing,
}) {
  return showDidoBottomSheet<void>(
    context: context,
    title: existing == null ? 'Nouvelle adresse' : 'Modifier l\'adresse',
    child: _AddressSheetBody(
      customerId: customerId,
      existing: existing,
    ),
  );
}

class _AddressSheetBody extends ConsumerStatefulWidget {
  const _AddressSheetBody({required this.customerId, this.existing});
  final String customerId;
  final CustomerAddress? existing;

  @override
  ConsumerState<_AddressSheetBody> createState() =>
      _AddressSheetBodyState();
}

class _AddressSheetBodyState extends ConsumerState<_AddressSheetBody> {
  late final TextEditingController _label;
  late final TextEditingController _addressLine;
  late final TextEditingController _city;
  late final TextEditingController _deliveryNotes;
  String? _governorate;
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _addressLine = TextEditingController(text: e?.addressLine ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _deliveryNotes = TextEditingController(text: e?.deliveryNotes ?? '');
    _governorate = e?.governorate;
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _addressLine.dispose();
    _city.dispose();
    _deliveryNotes.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_saving) return false;
    if (_addressLine.text.trim().isEmpty) return false;
    if (_city.text.trim().isEmpty) return false;
    if (_governorate == null) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier =
        ref.read(customerAddressesProvider(widget.customerId).notifier);

    final label = _label.text.trim();
    final addressLine = _addressLine.text.trim();
    final city = _city.text.trim();
    final deliveryNotes = _deliveryNotes.text.trim();

    try {
      if (widget.existing == null) {
        await notifier.create(
          addressLine: addressLine,
          city: city,
          governorate: _governorate!,
          label: label.isEmpty ? null : label,
          deliveryNotes: deliveryNotes.isEmpty ? null : deliveryNotes,
          isDefault: _isDefault,
        );
      } else {
        final e = widget.existing!;
        final wantClearLabel = label.isEmpty && (e.label?.isNotEmpty ?? false);
        final wantClearNotes = deliveryNotes.isEmpty &&
            (e.deliveryNotes?.isNotEmpty ?? false);
        await notifier.edit(
          e.id,
          label: !wantClearLabel && label != (e.label ?? '') ? label : null,
          clearLabel: wantClearLabel,
          addressLine: addressLine != e.addressLine ? addressLine : null,
          city: city != e.city ? city : null,
          governorate:
              _governorate != e.governorate ? _governorate : null,
          deliveryNotes:
              !wantClearNotes && deliveryNotes != (e.deliveryNotes ?? '')
                  ? deliveryNotes
                  : null,
          clearDeliveryNotes: wantClearNotes,
        );
        // Editing flips of isDefault are routed through setDefault.
        if (_isDefault && !e.isDefault) {
          await notifier.setDefault(e.id);
        }
      }
      if (!mounted) return;
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: context.colors.red,
          content: const Text('Échec de l\'enregistrement. Réessayer.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final keyboardPad = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.existing != null;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + keyboardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            label: 'Libellé',
            hint: 'Ex : Maison, Bureau…',
            controller: _label,
            maxLength: 50,
          ),
          SizedBox(height: context.spacing.space3),
          _Field(
            label: 'Adresse',
            hint: '12 rue de la Liberté…',
            controller: _addressLine,
            maxLength: 500,
            maxLines: 2,
            minLines: 1,
            required: true,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: context.spacing.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Field(
                  label: 'Ville',
                  hint: 'Tunis',
                  controller: _city,
                  maxLength: 100,
                  required: true,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SizedBox(width: context.spacing.space3),
              Expanded(child: _governorateDropdown(context)),
            ],
          ),
          SizedBox(height: context.spacing.space3),
          _Field(
            label: 'Notes de livraison',
            hint: 'Porte bleue, 3e étage…',
            controller: _deliveryNotes,
            maxLength: 500,
            maxLines: 3,
            minLines: 1,
          ),
          if (!isEdit) ...[
            SizedBox(height: context.spacing.space3),
            DidoToggleRow(
              label: 'Définir comme adresse par défaut',
              sub: 'Une seule adresse peut être par défaut.',
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
            ),
          ],
          SizedBox(height: context.spacing.space4),
          DidoButton.primary(
            label: isEdit ? 'Mettre à jour' : 'Enregistrer',
            loading: _saving,
            enabled: _canSave,
            onPressed: _canSave ? _save : null,
          ),
          if (isEdit && !widget.existing!.isDefault) ...[
            SizedBox(height: context.spacing.space2),
            DidoButton.secondary(
              label: 'Définir par défaut',
              icon: Icons.star_outline,
              onPressed: _saving
                  ? null
                  : () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref
                            .read(customerAddressesProvider(
                                    widget.customerId)
                                .notifier)
                            .setDefault(widget.existing!.id);
                        if (!mounted) return;
                        navigator.pop();
                      } catch (_) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: c.red,
                            content: const Text(
                              'Impossible de définir par défaut.',
                            ),
                          ),
                        );
                      }
                    },
            ),
          ],
        ],
      ),
    );
  }

  Widget _governorateDropdown(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: context.spacing.space2),
          child: Text(
            'Gouvernorat *',
            style: context.typography.label.copyWith(color: c.fg3),
          ),
        ),
        SizedBox(height: context.spacing.space2),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.surface0,
            border: Border.all(
              color: _governorate == null ? c.border1 : c.brandTeal,
              width: _governorate == null ? 1 : 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _governorate,
              hint: Text(
                'Choisir…',
                style: context.typography.body.copyWith(color: c.fg3),
              ),
              icon: Icon(Icons.keyboard_arrow_down, color: c.fg2),
              items: [
                for (final g in _tunisiaGovernorates)
                  DropdownMenuItem(value: g, child: Text(g)),
              ],
              onChanged: (v) => setState(() => _governorate = v),
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.required = false,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final bool required;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: context.spacing.space2),
          child: Text(
            required ? '$label *' : label,
            style: context.typography.label.copyWith(color: c.fg3),
          ),
        ),
        SizedBox(height: context.spacing.space2),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          style: context.typography.bodyMd.copyWith(color: c.fg1),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.typography.bodyMd.copyWith(color: c.fg3),
            filled: true,
            fillColor: c.surface0,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.brandTeal, width: 1.5),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}
