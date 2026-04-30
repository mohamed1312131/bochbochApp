import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../domain/boutique_models.dart';
import '../../domain/boutique_patch_input.dart';
import '../boutique_providers.dart';

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
  '#05687B', '#E74C3C', '#3498DB', '#2ECC71',
  '#F39C12', '#9B59B6', '#1ABC9C', '#E67E22',
];

class EditBoutiqueScreen extends ConsumerStatefulWidget {
  const EditBoutiqueScreen({super.key});

  @override
  ConsumerState<EditBoutiqueScreen> createState() => _EditBoutiqueScreenState();
}

class _EditBoutiqueScreenState extends ConsumerState<EditBoutiqueScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mfCtrl = TextEditingController();
  final _customColorCtrl = TextEditingController();

  String? _category;
  String? _city;
  String? _logoUrl;
  String? _brandColor;

  bool _seeded = false;
  bool _showCustomColor = false;
  bool _isLoading = false;
  bool _isUploadingLogo = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _mfCtrl.dispose();
    _customColorCtrl.dispose();
    super.dispose();
  }

  void _seedFromBoutique(Boutique b) {
    if (_seeded) return;
    _seeded = true;
    _nameCtrl.text = b.name;
    _addressCtrl.text = b.address ?? '';
    _emailCtrl.text = b.email ?? '';
    _mfCtrl.text = b.mf ?? '';
    _category = b.category;
    _city = b.city;
    _logoUrl = b.logoUrl;
    _brandColor = b.brandColor;
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _category != null &&
      _city != null &&
      !_isLoading;

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _isUploadingLogo = true);
    try {
      final repo = ref.read(boutiqueRepositoryProvider);
      final url = await repo.uploadLogo(picked);
      if (!mounted) return;
      setState(() {
        _logoUrl = url;
        _isUploadingLogo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploadingLogo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec du téléchargement')),
      );
    }
  }

  Future<void> _handleSave() async {
    if (!_canSave) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(boutiqueRepositoryProvider);
      await repo.update(BoutiquePatchInput(
        name: _nameCtrl.text.trim(),
        category: _category,
        city: _city,
        brandColor: _brandColor,
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        mf: _mfCtrl.text.trim().isEmpty ? null : _mfCtrl.text.trim(),
      ));
      ref.invalidate(currentBoutiqueProvider);
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Boutique mise à jour ✓')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Échec — réessaie')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final boutiqueAsync = ref.watch(currentBoutiqueProvider);
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text('Modifier ma boutique'),
        backgroundColor: context.appBackground,
        elevation: 0,
      ),
      body: boutiqueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (boutique) {
          _seedFromBoutique(boutique);
          final initial = _nameCtrl.text.isNotEmpty
              ? _nameCtrl.text.characters.first.toUpperCase()
              : 'D';
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenHorizontal,
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo avatar
                        Center(
                          child: GestureDetector(
                            onTap: _isUploadingLogo ? null : _pickAndUploadLogo,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: context.appBrand,
                                shape: BoxShape.circle,
                                image: _logoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_logoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _isUploadingLogo
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : (_logoUrl == null
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
                          controller: _nameCtrl,
                          onChanged: (_) => setState(() {}),
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
                              return ChoiceChip(
                                label: Text(cat),
                                selected: _category == cat,
                                onSelected: (_) => setState(() => _category = cat),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _Label('Ville'),
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<String>(
                          initialValue: _city,
                          isExpanded: true,
                          hint: const Text('Choisir un gouvernorat'),
                          items: _governorates
                              .map((g) =>
                                  DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _city = v);
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
                              final selected = _brandColor == hex;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _brandColor = hex;
                                    _showCustomColor = false;
                                  });
                                },
                                child: _Swatch(hex: hex, selected: selected),
                              );
                            }),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _showCustomColor = !_showCustomColor),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: context.appBorder, width: 1.5),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                child:
                                    Icon(Icons.add, color: context.appTextPrimary),
                              ),
                            ),
                          ],
                        ),
                        if (_showCustomColor) ...[
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _customColorCtrl,
                            decoration:
                                const InputDecoration(hintText: '#RRGGBB'),
                            onChanged: (v) {
                              if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(v)) {
                                setState(() => _brandColor = v);
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        Divider(color: context.appBorder),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Informations pour tes factures (optionnel)',
                          style: AppTypography.bodySmall.copyWith(
                            color: context.appTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Label('Adresse'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                              hintText: 'Adresse complète'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _Label('Email de contact'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              hintText: 'contact@boutique.tn'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _Label('Matricule fiscal'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _mfCtrl,
                          decoration: const InputDecoration(
                              hintText: 'Ex: 1234567A/M/B/000'),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.md,
                  ),
                  child: DidoButton.primary(
                    label: 'Enregistrer',
                    loading: _isLoading,
                    enabled: _canSave,
                    onPressed: _canSave ? _handleSave : null,
                  ),
                ),
              ],
            ),
          );
        },
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
