import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../domain/goal_models.dart';
import '../goal_providers.dart';

const _goalTypes = <String, String>{
  'REVENUE': 'Revenu',
  'PROFIT': 'Profit',
  'ORDERS': 'Commandes',
  'NEW_CUSTOMERS': 'Nouveaux clients',
};

class CreateGoalSheet extends ConsumerStatefulWidget {
  const CreateGoalSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreateGoalSheet(),
    );
  }

  @override
  ConsumerState<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends ConsumerState<CreateGoalSheet> {
  String _kind = 'TRACKED';
  String _goalType = 'REVENUE';
  final _targetCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _targetCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isTracked = _kind == 'TRACKED';
    final target = int.tryParse(_targetCtrl.text);
    final label = _labelCtrl.text.trim();

    if (isTracked && (target == null || target <= 0)) {
      setState(() => _error = 'Saisis une cible valide');
      return;
    }
    if (!isTracked && label.isEmpty) {
      setState(() => _error = 'Décris ton objectif');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final input = isTracked
        ? CreateGoalInput(
            kind: 'TRACKED',
            goalType: _goalType,
            targetValue: target,
          )
        : CreateGoalInput(
            kind: 'SELF_REPORT',
            label: label,
            targetValue: target,
          );

    try {
      await ref.read(goalRepositoryProvider).createGoal(input);
      ref.invalidate(activeGoalProvider);
      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      // 409: a goal already exists for this period (race or duplicate
      // submit). Treat as success — the user has a goal, refresh the
      // home card and close.
      final msg = e.toString().toLowerCase();
      final isConflict =
          msg.contains('conflict') || msg.contains('active_goal');
      if (isConflict) {
        ref.invalidate(activeGoalProvider);
        if (!mounted) return;
        navigator.pop();
        return;
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e is AppException ? e.message : 'Erreur. Réessaie.';
      });
      messenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTracked = _kind == 'TRACKED';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: context.appBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Quel est ton objectif ce mois-ci ?',
                style: AppTypography.h3.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                decoration: BoxDecoration(
                  color: context.appSurfaceL2,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.appBorder),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _KindOption(
                      label: 'Suivi automatique',
                      selected: isTracked,
                      onTap: () => setState(() => _kind = 'TRACKED'),
                    ),
                    _KindOption(
                      label: 'Objectif personnel',
                      selected: !isTracked,
                      onTap: () => setState(() => _kind = 'SELF_REPORT'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isTracked) ...[
                Text(
                  'Type de mesure',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 8,
                  children: _goalTypes.entries.map((e) {
                    return ChoiceChip(
                      label: Text(e.value),
                      selected: _goalType == e.key,
                      onSelected: (_) => setState(() => _goalType = e.key),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Cible',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '1500',
                    suffixText:
                        (_goalType == 'REVENUE' || _goalType == 'PROFIT')
                            ? 'TND'
                            : '',
                  ),
                ),
              ] else ...[
                Text(
                  'Décris ton objectif',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _labelCtrl,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: '+100 abonnés Facebook',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Cible (optionnelle)',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.appTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(hintText: '100 (optionnel)'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              DidoButton.primary(
                label: 'Créer mon objectif',
                loading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: TextButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: Text(
                    'Annuler',
                    style: AppTypography.body.copyWith(
                      color: context.appTextSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindOption extends StatelessWidget {
  const _KindOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? context.appBrand : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: selected ? AppColors.white : context.appTextPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
