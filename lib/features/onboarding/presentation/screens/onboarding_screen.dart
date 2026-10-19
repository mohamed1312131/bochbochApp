import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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

const _goalTypes = <_GoalTypeOption>[
  _GoalTypeOption('REVENUE', 'Revenu'),
  _GoalTypeOption('PROFIT', 'Profit'),
  _GoalTypeOption('ORDERS', 'Commandes'),
  _GoalTypeOption('NEW_CUSTOMERS', 'Nouveaux clients'),
];

class _GoalTypeOption {
  const _GoalTypeOption(this.value, this.label);
  final String value;
  final String label;
}

String _suffixForGoalType(String goalType) {
  return (goalType == 'REVENUE' || goalType == 'PROFIT') ? 'TND' : '';
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

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  bool _seededFromState = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
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

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(onboardingNotifierProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.surface0,
      body: SafeArea(
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Padding(
              padding: EdgeInsets.all(context.spacing.space6),
              child: const _ErrorBanner(
                message: 'Une erreur est survenue. Réessaie.',
              ),
            ),
          ),
          data: (s) {
            _seedControllersFromState(s);
            return PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StepWelcome(
                  onContinue: () => _goToPage(1),
                  onSkip: () {
                    ref.invalidate(currentBoutiqueProvider);
                    context.go('/home');
                  },
                ),
                _StepBoutique(
                  state: s,
                  nameCtrl: _nameCtrl,
                  onBack: () => _goToPage(0),
                  onNext: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await ref
                        .read(onboardingNotifierProvider.notifier)
                        .submitStep1();
                    if (!mounted) return;
                    if (ok) {
                      _goToPage(2);
                    } else {
                      final err = ref
                          .read(onboardingNotifierProvider)
                          .valueOrNull
                          ?.errorMessage;
                      if (err != null) {
                        messenger.showSnackBar(
                            SnackBar(content: Text(err)));
                      }
                    }
                  },
                  onSkip: () {
                    ref.invalidate(currentBoutiqueProvider);
                    context.go('/home');
                  },
                ),
                _StepGoal(
                  state: s,
                  targetCtrl: _targetCtrl,
                  labelCtrl: _labelCtrl,
                  onBack: () => _goToPage(1),
                  onSubmit: () async {
                    final router = GoRouter.of(context);
                    final ok = await ref
                        .read(onboardingNotifierProvider.notifier)
                        .submitStep2();
                    if (!mounted) return;
                    if (ok) router.go('/onboarding/success');
                  },
                  onSkip: () async {
                    final router = GoRouter.of(context);
                    final ok = await ref
                        .read(onboardingNotifierProvider.notifier)
                        .submitStep2(skip: true);
                    if (!mounted) return;
                    if (ok) router.go('/onboarding/success');
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

// ════════════════════════════════════════════════════════════
// Step 0 — Welcome
// ════════════════════════════════════════════════════════════
class _StepWelcome extends StatelessWidget {
  const _StepWelcome({required this.onContinue, required this.onSkip});

  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: context.spacing.space6),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(
            'DIDO',
            style: context.typography.h1.copyWith(
              color: c.fg1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              fontSize: 48,
            ),
          ),
          SizedBox(height: context.spacing.space6),
          Text(
            'Bienvenue',
            style: context.typography.h1.copyWith(color: c.fg1),
          ),
          SizedBox(height: context.spacing.space2),
          Text(
            'Configure ta boutique en 1 minute. Tu pourras tout modifier plus tard.',
            style: context.typography.bodyMd.copyWith(color: c.fg2),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.spacing.space6),
          const _ValueProp(text: 'Suivi automatique du bénéfice'),
          SizedBox(height: context.spacing.space3),
          const _ValueProp(text: 'Génération de contenu avec IA'),
          SizedBox(height: context.spacing.space3),
          const _ValueProp(text: 'Gestion des clients et commandes'),
          const Spacer(),
          DidoButton.primary(
            label: 'Commencer',
            onPressed: onContinue,
          ),
          SizedBox(height: context.spacing.space2),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Plus tard',
              style:
                  context.typography.bodyMd.copyWith(color: c.fg3),
            ),
          ),
          SizedBox(
              height: context.spacing.space4 +
                  MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _ValueProp extends StatelessWidget {
  const _ValueProp({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: c.fg2, shape: BoxShape.circle),
        ),
        SizedBox(width: context.spacing.space3),
        Expanded(
          child: Text(
            text,
            style: context.typography.bodyMd.copyWith(color: c.fg2),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Step 1 — Boutique
// ════════════════════════════════════════════════════════════
class _StepBoutique extends ConsumerWidget {
  const _StepBoutique({
    required this.state,
    required this.nameCtrl,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  final OnboardingState state;
  final TextEditingController nameCtrl;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final canAdvance = state.boutiqueName.trim().isNotEmpty &&
        state.boutiqueCategory != null &&
        state.boutiqueCity != null;

    return Column(
      children: [
        _Header(onBack: onBack),
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: context.spacing.space6),
          child: const _ProgressBar(currentStep: 1),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding:
                EdgeInsets.symmetric(horizontal: context.spacing.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.spacing.space4),
                Text(
                  'Configure ta boutique',
                  style: context.typography.h1.copyWith(color: c.fg1),
                ),
                SizedBox(height: context.spacing.space2),
                Text(
                  'Ces infos apparaissent sur tes factures.',
                  style:
                      context.typography.bodyMd.copyWith(color: c.fg3),
                ),
                SizedBox(height: context.spacing.space6),
                Center(
                  child: _LogoAvatar(
                    state: state,
                    onPick: () async {
                      if (state.isUploadingLogo) return;
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
                  ),
                ),
                SizedBox(height: context.spacing.space6),
                const _FieldLabel('Nom de la boutique'),
                SizedBox(height: context.spacing.space2),
                _AuthField(
                  controller: nameCtrl,
                  hint: 'Ex: Shop by Rania',
                  onChanged: notifier.setBoutiqueName,
                  textCapitalization: TextCapitalization.words,
                ),
                SizedBox(height: context.spacing.space4),
                const _FieldLabel('Que vends-tu ?'),
                SizedBox(height: context.spacing.space2),
                _CategoryChipsRow(
                  selected: state.boutiqueCategory,
                  onSelected: notifier.setBoutiqueCategory,
                ),
                SizedBox(height: context.spacing.space4),
                const _FieldLabel('Gouvernorat'),
                SizedBox(height: context.spacing.space2),
                _GovernorateDropdown(
                  value: state.boutiqueCity,
                  onChanged: (v) {
                    if (v != null) notifier.setBoutiqueCity(v);
                  },
                ),
                SizedBox(height: context.spacing.space6),
              ],
            ),
          ),
        ),
        _Footer(
          primary: DidoButton.primary(
            label: 'Suivant',
            loading: state.isLoading,
            enabled: canAdvance,
            onPressed: canAdvance ? onNext : null,
          ),
          onSkip: state.isLoading ? null : onSkip,
        ),
      ],
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar({required this.state, required this.onPick});
  final OnboardingState state;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final initial = state.boutiqueName.isNotEmpty
        ? state.boutiqueName.characters.first.toUpperCase()
        : 'D';
    return GestureDetector(
      onTap: state.isUploadingLogo ? null : onPick,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: c.brandTeal,
          shape: BoxShape.circle,
          image: state.logoUrl != null
              ? DecorationImage(
                  image: NetworkImage(state.logoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: state.isUploadingLogo
            ? SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: c.surface0,
                  strokeWidth: 2,
                ),
              )
            : (state.logoUrl == null
                ? Text(
                    initial,
                    style: context.typography.h1.copyWith(
                      color: c.surface0,
                      fontSize: 36,
                    ),
                  )
                : null),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Step 2 — Goal
// ════════════════════════════════════════════════════════════
class _StepGoal extends ConsumerWidget {
  const _StepGoal({
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
    final c = context.colors;
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final isTracked = state.goalKind == 'TRACKED';

    return Column(
      children: [
        _Header(onBack: onBack),
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: context.spacing.space6),
          child: const _ProgressBar(currentStep: 2),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding:
                EdgeInsets.symmetric(horizontal: context.spacing.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: context.spacing.space4),
                Text(
                  'Quel est ton objectif ce mois-ci ?',
                  style: context.typography.h1.copyWith(color: c.fg1),
                ),
                SizedBox(height: context.spacing.space2),
                Text(
                  'Tu peux le modifier à tout moment.',
                  style:
                      context.typography.bodyMd.copyWith(color: c.fg3),
                ),
                SizedBox(height: context.spacing.space6),
                _KindToggle(
                  selected: state.goalKind,
                  onSelected: notifier.setGoalKind,
                ),
                SizedBox(height: context.spacing.space4),
                if (isTracked) ...[
                  const _FieldLabel('Type de mesure'),
                  SizedBox(height: context.spacing.space2),
                  _GoalTypeChips(
                    selected: state.goalType,
                    onSelected: (v) {
                      notifier.setGoalType(v);
                      targetCtrl.text =
                          (state.goalTargetValue ?? _defaultTargetFor(v))
                              .toString();
                    },
                  ),
                  SizedBox(height: context.spacing.space4),
                  const _FieldLabel('Cible'),
                  SizedBox(height: context.spacing.space2),
                  _AuthField(
                    controller: targetCtrl,
                    hint: '1500',
                    keyboardType: TextInputType.number,
                    suffix: _suffixForGoalType(state.goalType),
                    onChanged: (v) =>
                        notifier.setGoalTargetValue(int.tryParse(v)),
                  ),
                ] else ...[
                  const _FieldLabel('Décris ton objectif'),
                  SizedBox(height: context.spacing.space2),
                  _AuthField(
                    controller: labelCtrl,
                    hint: '+100 abonnés Facebook',
                    maxLength: 200,
                    onChanged: notifier.setGoalLabel,
                  ),
                  SizedBox(height: context.spacing.space4),
                  const _FieldLabel('Cible (optionnelle)'),
                  SizedBox(height: context.spacing.space2),
                  _AuthField(
                    controller: targetCtrl,
                    hint: '100 (optionnel)',
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        notifier.setGoalTargetValue(int.tryParse(v)),
                  ),
                ],
                if (state.errorMessage != null) ...[
                  SizedBox(height: context.spacing.space3),
                  _ErrorBanner(message: state.errorMessage!),
                ],
                SizedBox(height: context.spacing.space6),
              ],
            ),
          ),
        ),
        _Footer(
          primary: DidoButton.primary(
            label: 'Commencer',
            loading: state.isLoading,
            onPressed: onSubmit,
          ),
          onSkip: state.isLoading ? null : onSkip,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Header / Footer / ProgressBar
// ════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.space6,
        context.spacing.space3,
        context.spacing.space6,
        context.spacing.space3,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: c.fg1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.primary, this.onSkip});
  final Widget primary;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: c.surface0,
        border: Border(top: BorderSide(color: c.border1, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(
        context.spacing.space6,
        context.spacing.space3,
        context.spacing.space6,
        context.spacing.space3 + bottomInset,
      ),
      child: Column(
        children: [
          primary,
          if (onSkip != null) ...[
            SizedBox(height: context.spacing.space1),
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Plus tard',
                style:
                    context.typography.bodyMd.copyWith(color: c.fg3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: c.fg1,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(width: context.spacing.space2),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: 3,
                decoration: BoxDecoration(
                  color: currentStep >= 2 ? c.fg1 : c.border1,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: context.spacing.space2),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Étape $currentStep sur 2',
            style: context.typography.bodySmall.copyWith(color: c.fg3),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
// Inputs / chips / dropdown / toggle
// ════════════════════════════════════════════════════════════
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.typography.bodyMd.copyWith(
        color: context.colors.fg1,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.suffix,
    this.maxLength,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? suffix;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(context.radius.radiusInput);
    OutlineInputBorder b(Color color, double width) =>
        OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(color: color, width: width));

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      onChanged: onChanged,
      style: context.typography.input.copyWith(color: c.fg1),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.typography.input.copyWith(color: c.fg3),
        suffixText: suffix,
        suffixStyle: context.typography.bodyMd.copyWith(color: c.fg3),
        filled: true,
        fillColor: c.surface1,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.spacing.space3,
          vertical: 14,
        ),
        isDense: true,
        counterText: '',
        border: b(c.border1, 1),
        enabledBorder: b(c.border1, 1),
        focusedBorder: b(c.fg1, 1.5),
        errorBorder: b(c.red, 1),
        focusedErrorBorder: b(c.red, 1.5),
        errorStyle:
            context.typography.bodySmall.copyWith(color: c.redFg),
      ),
    );
  }
}

class _CategoryChipsRow extends StatelessWidget {
  const _CategoryChipsRow({
    required this.selected,
    required this.onSelected,
  });
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) =>
            SizedBox(width: context.spacing.space2),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          return _Chip(
            label: cat,
            selected: selected == cat,
            onTap: () => onSelected(cat),
          );
        },
      ),
    );
  }
}

class _GoalTypeChips extends StatelessWidget {
  const _GoalTypeChips({
    required this.selected,
    required this.onSelected,
  });
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final gt in _goalTypes)
          _Chip(
            label: gt.label,
            selected: selected == gt.value,
            onTap: () => onSelected(gt.value),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motion.tap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.fg1 : c.surface1,
          border: Border.all(
            color: selected ? c.fg1 : c.border1,
            width: 1,
          ),
          borderRadius:
              BorderRadius.circular(context.radius.radiusChip),
        ),
        child: Text(
          label,
          style: context.typography.bodyMd.copyWith(
            color: selected ? c.surface0 : c.fg1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _GovernorateDropdown extends StatelessWidget {
  const _GovernorateDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1, width: 1),
        borderRadius:
            BorderRadius.circular(context.radius.radiusInput),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: c.surface1,
          hint: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: context.spacing.space3),
            child: Text(
              'Choisir un gouvernorat',
              style: context.typography.input.copyWith(color: c.fg3),
            ),
          ),
          icon: Padding(
            padding:
                EdgeInsets.only(right: context.spacing.space3),
            child: Icon(Icons.expand_more, size: 20, color: c.fg2),
          ),
          items: _governorates
              .map(
                (gov) => DropdownMenuItem(
                  value: gov,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.spacing.space3),
                    child: Text(
                      gov,
                      style:
                          context.typography.input.copyWith(color: c.fg1),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _KindToggle extends StatelessWidget {
  const _KindToggle({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius:
            BorderRadius.circular(context.radius.radiusInput),
      ),
      child: Row(
        children: [
          Expanded(
            child: _KindButton(
              label: 'Suivi automatique',
              selected: selected == 'TRACKED',
              onTap: () => onSelected('TRACKED'),
            ),
          ),
          Expanded(
            child: _KindButton(
              label: 'Objectif personnel',
              selected: selected == 'SELF_REPORT',
              onTap: () => onSelected('SELF_REPORT'),
            ),
          ),
        ],
      ),
    );
  }
}

class _KindButton extends StatelessWidget {
  const _KindButton({
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: context.motion.tap,
        curve: context.motion.easeOut,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? c.surface0 : c.surface2,
          borderRadius: BorderRadius.circular(
              context.radius.radiusInput - 2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: context.typography.bodyMd.copyWith(
            color: selected ? c.fg1 : c.fg2,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.all(context.spacing.space3),
      decoration: BoxDecoration(
        color: c.coralTint12,
        borderRadius:
            BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: c.coralFg),
          SizedBox(width: context.spacing.space2),
          Expanded(
            child: Text(
              message,
              style: context.typography.bodySmall.copyWith(
                color: c.coralFg,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
