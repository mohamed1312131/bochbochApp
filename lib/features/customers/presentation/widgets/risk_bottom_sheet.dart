import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../domain/customer_models.dart';
import '../providers/customer_provider.dart';

/// FLUTTER_SPEC §3.1 — risk badge bottom sheet. Lets the seller pick a
/// new risk level + optional reason, plus shows when the level was
/// last updated.
Future<void> showRiskBottomSheet({
  required BuildContext context,
  required CustomerDetail customer,
}) {
  return showDidoBottomSheet<void>(
    context: context,
    title: 'Niveau de risque',
    child: _RiskBody(customer: customer),
  );
}

class _RiskBody extends ConsumerStatefulWidget {
  const _RiskBody({required this.customer});
  final CustomerDetail customer;

  @override
  ConsumerState<_RiskBody> createState() => _RiskBodyState();
}

class _RiskBodyState extends ConsumerState<_RiskBody> {
  late RiskLevel _level;
  late final TextEditingController _reason;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _level = widget.customer.riskLevel;
    _reason = TextEditingController(text: widget.customer.riskReason ?? '');
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final reason = _reason.text.trim();
      final priorReason = widget.customer.riskReason ?? '';
      await ref
          .read(customerDetailProvider(widget.customer.id).notifier)
          .setRisk(
            riskLevel: _level,
            riskReason: reason.isEmpty ? null : reason,
            clearReason: reason.isEmpty && priorReason.isNotEmpty,
          );
      if (!mounted) return;
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: context.colors.red,
          content: const Text('Échec de la mise à jour du risque.'),
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
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + keyboardPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LevelRow(
            level: RiskLevel.green,
            emoji: '🟢',
            title: 'Risque faible',
            description: 'Aucun signal négatif. COD activé.',
            selected: _level == RiskLevel.green,
            onTap: () => setState(() => _level = RiskLevel.green),
          ),
          SizedBox(height: context.spacing.space2),
          _LevelRow(
            level: RiskLevel.yellow,
            emoji: '🟡',
            title: 'Risque modéré',
            description: 'Comportement à surveiller (retours, retards…).',
            selected: _level == RiskLevel.yellow,
            onTap: () => setState(() => _level = RiskLevel.yellow),
          ),
          SizedBox(height: context.spacing.space2),
          _LevelRow(
            level: RiskLevel.red,
            emoji: '🔴',
            title: 'Risque élevé',
            description: 'Refus COD répétés, fraude, problème de livraison.',
            selected: _level == RiskLevel.red,
            onTap: () => setState(() => _level = RiskLevel.red),
          ),
          SizedBox(height: context.spacing.space4),
          Padding(
            padding: EdgeInsets.only(left: context.spacing.space2),
            child: Text(
              'Raison · optionnel',
              style: context.typography.label.copyWith(color: c.fg3),
            ),
          ),
          SizedBox(height: context.spacing.space2),
          TextField(
            controller: _reason,
            maxLength: 500,
            maxLines: 3,
            minLines: 2,
            style: context.typography.bodyMd.copyWith(color: c.fg1),
            decoration: InputDecoration(
              hintText: 'Ex : 3 refus COD ce mois',
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
          if (widget.customer.riskUpdatedAt != null) ...[
            SizedBox(height: context.spacing.space3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, size: 14, color: c.fg2),
                  SizedBox(width: context.spacing.space2),
                  Expanded(
                    child: Text(
                      'Niveau défini le ${DateFormatter.short(widget.customer.riskUpdatedAt!)}',
                      style: context.typography.bodySmall
                          .copyWith(color: c.fg2),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.level,
    required this.emoji,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });
  final RiskLevel level;
  final String emoji;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.radius.radiusCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? c.brandTealTint08 : c.surface0,
          border: Border.all(
            color: selected ? c.brandTeal : c.border1,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            SizedBox(width: context.spacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.typography.h4.copyWith(color: c.fg1),
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: context.typography.bodySmall
                        .copyWith(color: c.fg3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
