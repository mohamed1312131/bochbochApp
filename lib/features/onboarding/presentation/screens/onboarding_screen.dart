import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../boutiques/presentation/boutique_providers.dart';
import '../onboarding_notifier.dart';

const _categories = <String>[
  'Vêtements',
  'Accessoires',
  'Beauté',
  'Alimentation',
  'Électronique',
  'Maison',
  'Services',
  'Autre',
];

const _governorates = <String>[
  'Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Zaghouan',
  'Bizerte', 'Béja', 'Jendouba', 'Le Kef', 'Siliana', 'Sousse',
  'Monastir', 'Mahdia', 'Sfax', 'Kairouan', 'Kasserine', 'Sidi Bouzid',
  'Gabès', 'Medenine', 'Tataouine', 'Gafsa', 'Tozeur', 'Kebili',
  'Autre pays',
];

const _swatches = <String>[
  '#05687B',
  '#E74C3C',
  '#3498DB',
  '#2ECC71',
  '#F39C12',
  '#9B59B6',
  '#1ABC9C',
  '#E67E22',
];

const _goalTypes = <String, String>{
  'REVENUE': 'Revenu',
  'PROFIT': 'Profit',
  'ORDERS': 'Commandes',
  'NEW_CUSTOMERS': 'Nouveaux clients',
};

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameCtrl = TextEditingController();
  final _customColorCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  bool _showCustomColor = false;
  bool _seededFromState = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _customColorCtrl.dispose();
    _targetCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  void _seedControllersFromState(OnboardingState s) {
    if (_seededFromState) return;
    _seededFromState = true;
    _nameCtrl.text = s.boutiqueName;
    if (s.goalTargetValue != null) {
      _targetCtrl.text = s.goalTargetValue.toString();
    } else {
      _targetCtrl.text = _defaultTargetFor(s.goalType).toString();
    }
    _labelCtrl.text = s.goalLabel ?? '';
  }

  int _defaultTargetFor(String goalType) {
    switch (goalType) {
      case 'REVENUE':
        return 1500;
      case 'PROFIT':
        return 500;
      case 'ORDERS':
      case 'NEW_CUSTOMERS':
        return 100;
      default:
        return 1500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(onboardingNotifierProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
          data: (s) {
            _seedControllersFromState(s);
            return PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1(
                  state: s,
                  nameCtrl: _nameCtrl,
                  customColorCtrl: _customColorCtrl,
                  showCustomColor: _showCustomColor,
                  onToggleCustomColor: (v) =>
                      setState(() => _showCustomColor = v),
                  onNext: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await ref
                        .read(onboardingNotifierProvider.notifier)
                        .submitStep1();
                    if (!mounted) return;
                    if (ok) {
                      _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    } else if (s.errorMessage != null) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(s.errorMessage!)),
                      );
                    }
                  },
                  onSkip: () {
                    ref.invalidate(currentBoutiqueProvider);
                    context.go('/home');
                  },
                ),
                _Step2(
                  state: s,
                  targetCtrl: _targetCtrl,
                  labelCtrl: _labelCtrl,
                  onBack: () => _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                  onSubmit: () async {
                    final router = GoRouter.of(context);
                    final ok = await ref
                        .read(onboardingNotifierProvider.notifier)
                        .submitStep2();
                    if (!mounted) return;
                    if (ok) router.go('/home');
                  },
                  onSkip: () async {
                    final router = GoRouter.of(context);
                    final ok = await ref
                        .read(onboardingNotifierProvider.notifier)
                        .submitStep2(skip: true);
                    if (!mounted) return;
                    if (ok) router.go('/home');
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Step 1: boutique setup ───────────────────────────────────────────────

class _Step1 extends ConsumerWidget {
  const _Step1({
    required this.state,
    required this.nameCtrl,
    required this.customColorCtrl,
    required this.showCustomColor,
    required this.onToggleCustomColor,
    required this.onNext,
    required this.onSkip,
  });

  final OnboardingState state;
  final TextEditingController nameCtrl;
  final TextEditingController customColorCtrl;
  final bool showCustomColor;
  final ValueChanged<bool> onToggleCustomColor;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final canAdvance = state.boutiqueName.trim().isNotEmpty &&
        state.boutiqueCategory != null &&
        state.boutiqueCity != null;
    final initial = state.boutiqueName.isNotEmpty
        ? state.boutiqueName.characters.first.toUpperCase()
        : 'D';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurons ta boutique',
            style: AppTypography.h1.copyWith(color: context.appTextPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ces infos apparaissent sur tes PDFs et factures.',
            style: AppTypography.body.copyWith(color: context.appTextSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Logo avatar
          Center(
            child: GestureDetector(
              onTap: state.isUploadingLogo
                  ? null
                  : () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 85,
                      );
                      if (picked != null) {
                        await notifier.uploadLogo(picked);
                      }
                    },
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: context.appBrand,
                  shape: BoxShape.circle,
                  image: state.logoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(state.logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: state.isUploadingLogo
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : (state.logoUrl == null
                        ? Center(
                            child: Text(
                              initial,
                              style: AppTypography.h1.copyWith(
                                color: AppColors.white,
                                fontSize: 36,
                              ),
                            ),
                          )
                        : null),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Label('Nom de la boutique'),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(hintText: 'Ex: Shop by Rania'),
            onChanged: notifier.setBoutiqueName,
          ),
          const SizedBox(height: AppSpacing.lg),
          _Label('Que vends-tu ?'),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = state.boutiqueCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => notifier.setBoutiqueCategory(cat),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _Label('Ville'),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<String>(
            initialValue: state.boutiqueCity,
            isExpanded: true,
            hint: const Text('Choisir un gouvernorat'),
            items: _governorates
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) {
              if (v != null) notifier.setBoutiqueCity(v);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          _Label('Couleur de ta marque (optionnel)'),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._swatches.map((hex) {
                final selected = state.brandColor == hex;
                return GestureDetector(
                  onTap: () {
                    onToggleCustomColor(false);
                    notifier.setBrandColor(hex);
                  },
                  child: _Swatch(hex: hex, selected: selected),
                );
              }),
              GestureDetector(
                onTap: () => onToggleCustomColor(!showCustomColor),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: context.appBorder, width: 1.5),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.add, color: context.appTextPrimary),
                ),
              ),
            ],
          ),
          if (showCustomColor) ...[
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: customColorCtrl,
              decoration: const InputDecoration(hintText: '#RRGGBB'),
              onChanged: (v) {
                if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(v)) {
                  notifier.setBrandColor(v);
                }
              },
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          DidoButton.primary(
            label: 'Suivant',
            loading: state.isLoading,
            enabled: canAdvance,
            onPressed: canAdvance ? onNext : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: state.isLoading ? null : onSkip,
              child: Text(
                'Plus tard',
                style: AppTypography.body.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.hex, required this.selected});
  final String hex;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF${hex.substring(1)}', radix: 16));
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: context.appTextPrimary, width: 2)
            : null,
      ),
      child: selected
          ? const Icon(Icons.check, color: AppColors.white, size: 18)
          : null,
    );
  }
}

// ── Step 2: first goal ───────────────────────────────────────────────────

class _Step2 extends ConsumerWidget {
  const _Step2({
    required this.state,
    required this.targetCtrl,
    required this.labelCtrl,
    required this.onBack,
    required this.onSubmit,
    required this.onSkip,
  });

  final OnboardingState state;
  final TextEditingController targetCtrl;
  final TextEditingController labelCtrl;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final isTracked = state.goalKind == 'TRACKED';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Quel est ton objectif ce mois-ci ?',
            style: AppTypography.h1.copyWith(color: context.appTextPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tu peux le modifier à tout moment.',
            style: AppTypography.body.copyWith(color: context.appTextSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Kind toggle
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
                  onTap: () => notifier.setGoalKind('TRACKED'),
                ),
                _KindOption(
                  label: 'Objectif personnel',
                  selected: !isTracked,
                  onTap: () => notifier.setGoalKind('SELF_REPORT'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isTracked) ...[
            _Label('Type de mesure'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              children: _goalTypes.entries.map((e) {
                final selected = state.goalType == e.key;
                return ChoiceChip(
                  label: Text(e.value),
                  selected: selected,
                  onSelected: (_) {
                    notifier.setGoalType(e.key);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Label('Cible'),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '1500',
                suffixText: (state.goalType == 'REVENUE' ||
                        state.goalType == 'PROFIT')
                    ? 'TND'
                    : '',
              ),
              onChanged: (v) {
                final n = int.tryParse(v);
                notifier.setGoalTargetValue(n);
              },
            ),
          ] else ...[
            _Label('Décris ton objectif'),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: labelCtrl,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '+100 abonnés Facebook',
              ),
              onChanged: notifier.setGoalLabel,
            ),
            const SizedBox(height: AppSpacing.sm),
            _Label('Cible (optionnelle)'),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '100 (optionnel)'),
              onChanged: (v) {
                final n = int.tryParse(v);
                notifier.setGoalTargetValue(n);
              },
            ),
          ],
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          DidoButton.primary(
            label: 'Commencer',
            loading: state.isLoading,
            onPressed: onSubmit,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: state.isLoading ? null : onSkip,
              child: Text(
                'Plus tard',
                style: AppTypography.body.copyWith(
                  color: context.appTextSecondary,
                ),
              ),
            ),
          ),
        ],
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.body.copyWith(
        color: context.appTextPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
