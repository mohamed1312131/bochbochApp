import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../domain/customer_models.dart';
import '../providers/customer_provider.dart';

/// FLUTTER_SPEC §3.5 — tag picker. REPLACE semantics: the sheet sends
/// the full desired tag set on save (omitting `tags` keeps the
/// previous set; sending `[]` clears them all).
Future<void> showTagPickerSheet({
  required BuildContext context,
  required CustomerDetail customer,
}) {
  return showDidoBottomSheet<void>(
    context: context,
    title: 'Tags du client',
    child: _TagPickerBody(customer: customer),
  );
}

const _presetTags = <String>[
  'VIP',
  'Grossiste',
  'Influenceur',
  'Retourneur fréquent',
  'Fidèle',
  'Nouveau',
];

class _TagPickerBody extends ConsumerStatefulWidget {
  const _TagPickerBody({required this.customer});
  final CustomerDetail customer;

  @override
  ConsumerState<_TagPickerBody> createState() => _TagPickerBodyState();
}

class _TagPickerBodyState extends ConsumerState<_TagPickerBody> {
  late Set<String> _selected;
  final TextEditingController _custom = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.customer.tags};
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _toggle(String tag) {
    setState(() {
      if (_selected.contains(tag)) {
        _selected.remove(tag);
      } else {
        _selected.add(tag);
      }
    });
  }

  void _addCustom() {
    final raw = _custom.text.trim();
    if (raw.isEmpty) return;
    if (raw.length > 50) return;
    setState(() {
      _selected.add(raw);
      _custom.clear();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(customerDetailProvider(widget.customer.id).notifier)
          .setProfile(tags: _selected.toList()..sort());
      if (!mounted) return;
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: context.colors.red,
          content: const Text('Échec de la mise à jour des tags.'),
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

    final presetSet = _presetTags.toSet();
    final customSelected = _selected.where((t) => !presetSet.contains(t));

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + keyboardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choisis dans la liste ou crée le tien.',
            style: context.typography.body.copyWith(color: c.fg2),
          ),
          SizedBox(height: context.spacing.space3),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _presetTags)
                _TagToggle(
                  label: tag,
                  selected: _selected.contains(tag),
                  onTap: () => _toggle(tag),
                ),
              for (final tag in customSelected)
                _TagToggle(
                  label: tag,
                  selected: true,
                  onTap: () => _toggle(tag),
                ),
            ],
          ),
          SizedBox(height: context.spacing.space4),
          Padding(
            padding: EdgeInsets.only(left: context.spacing.space2),
            child: Text(
              'CRÉER UN TAG',
              style: context.typography.label.copyWith(color: c.fg3),
            ),
          ),
          SizedBox(height: context.spacing.space2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _custom,
                  maxLength: 50,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCustom(),
                  style: context.typography.bodyMd.copyWith(color: c.fg1),
                  decoration: InputDecoration(
                    hintText: 'Nom du tag',
                    hintStyle:
                        context.typography.bodyMd.copyWith(color: c.fg3),
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
              ),
              SizedBox(width: context.spacing.space2),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _addCustom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.fg1,
                    foregroundColor: c.surface0,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Créer',
                    style: context.typography.button
                        .copyWith(color: c.surface0),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacing.space4),
          DidoButton.primary(
            label: 'Enregistrer',
            loading: _saving,
            enabled: !_saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _TagToggle extends StatelessWidget {
  const _TagToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.fg1 : c.surface0,
          border: Border.all(color: selected ? c.fg1 : c.border1),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: context.typography.button.copyWith(
            color: selected ? c.surface0 : c.fg1,
          ),
        ),
      ),
    );
  }
}
