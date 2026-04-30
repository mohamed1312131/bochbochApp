import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../domain/goal_progress_models.dart';

const _goalTypeLabels = <String, String>{
  'REVENUE': 'Objectif Revenu',
  'PROFIT': 'Objectif Profit',
  'ORDERS': 'Objectif Commandes',
  'NEW_CUSTOMERS': 'Nouveaux clients',
};

bool _isMoneyType(String? goalType) =>
    goalType == 'REVENUE' || goalType == 'PROFIT';

class ActiveGoalCard extends StatelessWidget {
  const ActiveGoalCard({super.key, required this.goal});
  final GoalWithProgress goal;

  @override
  Widget build(BuildContext context) {
    final title = _goalTypeLabels[goal.goalType] ?? 'Objectif';
    final progress =
        ((goal.progressPercent ?? 0) / 100).clamp(0.0, 1.0).toDouble();
    final isMoney = _isMoneyType(goal.goalType);
    final current = goal.currentValue ?? 0;
    final target = goal.targetValue ?? 0;
    final progressLabel = isMoney
        ? '${MillimesFormatter.format(current)} / ${MillimesFormatter.format(target)}'
        : '$current / $target ${goal.goalType == "ORDERS" ? "commandes" : "clients"}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h4.copyWith(
                    color: context.appTextPrimary,
                  ),
                ),
              ),
              _DaysPill(daysRemaining: goal.daysRemaining),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: context.appSurfaceL2,
              valueColor: AlwaysStoppedAnimation(context.appBrand),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            progressLabel,
            style: AppTypography.bodySmall.copyWith(
              color: context.appTextSecondary,
            ),
          ),
          if (goal.dailyPaceRequired != null && goal.dailyPaceRequired! > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              isMoney
                  ? 'Tu dois faire ${MillimesFormatter.format(goal.dailyPaceRequired!)}/jour'
                  : 'Tu dois faire ${goal.dailyPaceRequired}/jour',
              style: AppTypography.bodySmall.copyWith(
                color: context.appTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SelfReportGoalCard extends StatelessWidget {
  const SelfReportGoalCard({super.key, required this.goal});
  final GoalWithProgress goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              goal.label ?? 'Objectif personnel',
              style: AppTypography.body.copyWith(
                color: context.appTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _DaysPill(daysRemaining: goal.daysRemaining),
        ],
      ),
    );
  }
}

class NoGoalCard extends StatelessWidget {
  const NoGoalCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, color: context.appBrand),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Définis ton objectif du mois',
                style: AppTypography.body.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.appTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class NoBoutiqueCard extends StatelessWidget {
  const NoBoutiqueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/onboarding'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.appBrandLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.appBrand.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.store_outlined, color: context.appBrand),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Configure ta boutique',
                style: AppTypography.body.copyWith(
                  color: context.appTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.appBrand),
          ],
        ),
      ),
    );
  }
}

class _DaysPill extends StatelessWidget {
  const _DaysPill({required this.daysRemaining});
  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: context.appSurfaceL2,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        'J-$daysRemaining',
        style: AppTypography.caption.copyWith(
          color: context.appTextSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
