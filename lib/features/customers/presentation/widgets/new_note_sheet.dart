import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_toggle_row.dart';
import '../../domain/customer_note_models.dart';
import '../providers/customer_notes_provider.dart';

/// FLUTTER_SPEC §3.6 — sheet for creating or editing a single note.
/// Pass [existing] to edit; omit to create.
Future<void> showNoteSheet({
  required BuildContext context,
  required String customerId,
  CustomerNote? existing,
}) {
  return showDidoBottomSheet<void>(
    context: context,
    title: existing == null ? 'Nouvelle note' : 'Modifier la note',
    child: _NoteSheetBody(customerId: customerId, existing: existing),
  );
}

class _NoteSheetBody extends ConsumerStatefulWidget {
  const _NoteSheetBody({required this.customerId, this.existing});
  final String customerId;
  final CustomerNote? existing;

  @override
  ConsumerState<_NoteSheetBody> createState() => _NoteSheetBodyState();
}

class _NoteSheetBodyState extends ConsumerState<_NoteSheetBody> {
  late final TextEditingController _controller;
  late bool _pinned;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existing?.content ?? '');
    _pinned = widget.existing?.isPinned ?? false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _saving) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier =
        ref.read(customerNotesProvider(widget.customerId).notifier);
    try {
      if (widget.existing == null) {
        await notifier.create(content: content, isPinned: _pinned);
      } else {
        await notifier.edit(
          widget.existing!.id,
          content: content == widget.existing!.content ? null : content,
          isPinned: _pinned == widget.existing!.isPinned ? null : _pinned,
        );
      }
      if (!mounted) return;
      navigator.pop();
    } catch (e) {
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
    final padding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            maxLength: 2000,
            maxLines: null,
            minLines: 5,
            textInputAction: TextInputAction.newline,
            style: context.typography.bodyMd.copyWith(color: c.fg1),
            decoration: InputDecoration(
              hintText: 'Ex : préfère Aramex, appeler avant livraison…',
              hintStyle: context.typography.bodyMd.copyWith(color: c.fg3),
              filled: true,
              fillColor: c.surface0,
              contentPadding: const EdgeInsets.all(14),
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
          SizedBox(height: context.spacing.space3),
          DidoToggleRow(
            label: 'Épingler en haut de la liste',
            sub: 'Une seule note peut être épinglée à la fois.',
            value: _pinned,
            onChanged: (v) => setState(() => _pinned = v),
          ),
          SizedBox(height: context.spacing.space4),
          DidoButton.primary(
            label: widget.existing == null ? 'Enregistrer' : 'Mettre à jour',
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
