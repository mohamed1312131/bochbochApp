import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_scale_tap.dart';
import '../../../../shared/widgets/dido_segmented.dart';
import '../../../stock/domain/stock_models.dart';
import '../../../stock/presentation/providers/stock_provider.dart';
import '../../../stock/presentation/widgets/stock_quantity_stepper.dart';
import '../../../stock/presentation/widgets/stock_settings_backorder_card.dart';
import '../providers/product_provider.dart';
import '../widgets/bundle_component_draft.dart';
import '../widgets/bundle_components_section.dart';
import '../widgets/variant_draft.dart';
import '../widgets/variants_section.dart';

// NOTE: This screen creates either:
//  - a single-variant product (the "Default" variant carries
//    initialStock + per-product lowStockThreshold + backorder), or
//  - a multi-variant product when `_hasVariants` is on (the seller
//    composes a list of VariantDraft entries, each with its own
//    attribute pairs + stock + optional price overrides; submit
//    posts them in one call via POST /products `variants[]`).
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();

  XFile? _selectedImage;

  // ── Stock-aware fields (chunk 8a) ──
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  int _lowStockThreshold = 3;
  bool _backorderEnabled = false;

  // ── Bundle mode (chunk 8b-2) ──
  bool _isBundle = false;
  final List<BundleComponentDraft> _bundleComponents = [];

  // ── Multi-variant mode ──
  bool _hasVariants = false;
  final List<VariantDraft> _variants = [];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_rebuild);
    _costPriceController.addListener(_rebuild);
    _sellPriceController.addListener(_rebuild);
    _stockController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  int _parseTnd(String value) {
    final tnd = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return MillimesFormatter.toMillimes(tnd);
  }

  double get _profitMargin {
    final cost =
        double.tryParse(_costPriceController.text.replaceAll(',', '.')) ?? 0;
    final sell =
        double.tryParse(_sellPriceController.text.replaceAll(',', '.')) ?? 0;
    return sell - cost;
  }

  double get _profitPct {
    final sell =
        double.tryParse(_sellPriceController.text.replaceAll(',', '.')) ?? 0;
    if (sell <= 0) return 0;
    return (_profitMargin / sell) * 100;
  }

  bool get _canSave {
    final commonOk =
        _nameController.text.trim().isNotEmpty &&
        _costPriceController.text.trim().isNotEmpty &&
        _sellPriceController.text.trim().isNotEmpty;
    if (!commonOk) return false;
    if (_isBundle) {
      return _bundleComponents.isNotEmpty;
    }
    if (_hasVariants) {
      return _variants.isNotEmpty && _variants.every((v) => v.isValid);
    }
    return _stockController.text.trim().isNotEmpty;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PhotoSourceSheet(),
    );
    if (source == null) return;
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final usingVariants = !_isBundle && _hasVariants && _variants.isNotEmpty;
    await ref
        .read(addProductProvider.notifier)
        .createProduct(
          name: _nameController.text.trim(),
          baseCostPrice: _parseTnd(_costPriceController.text),
          baseSellPrice: _parseTnd(_sellPriceController.text),
          // Multi-variant ignores initialStock server-side, but we keep
          // it at 0 to satisfy the schema's `min(0)` default.
          initialStock: (_isBundle || usingVariants)
              ? 0
              : (int.tryParse(_stockController.text) ?? 0),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _selectedCategoryName,
          categoryId: _selectedCategoryId,
          lowStockThreshold: _isBundle ? null : _lowStockThreshold,
          backorderEnabled: _isBundle ? null : _backorderEnabled,
          isBundle: _isBundle ? true : null,
          imagePath: _selectedImage?.path,
          variants: usingVariants
              ? [for (final v in _variants) v.toJson()]
              : null,
        );

    if (!_isBundle) return;
    final created = ref.read(addProductProvider).createdProduct;
    if (created == null || _bundleComponents.isEmpty) return;
    try {
      await ref.read(stockRepositoryProvider).upsertBundle(created.id, [
        for (final c in _bundleComponents)
          BundleComponent(
            componentVariantId: c.variantId,
            componentProductName: c.productName,
            componentSku: c.sku,
            qtyPerBundle: c.qtyPerBundle,
            componentCost: c.componentCost,
          ),
      ]);
    } catch (_) {
      // Bundle composition is non-fatal: product is created, but the
      // user will need to revisit and re-attach components. Surface
      // this in chunk 9 polish.
    }
  }

  Future<void> _pickCategory() async {
    // Force the future to settle (or refresh on error) before opening the
    // sheet so the in-sheet content matches reality. Without this, the
    // first tap after navigation can race the provider's initial fetch and
    // surface an empty list even when categories exist.
    final c = context.colors;
    List<Category> categories;
    try {
      categories = await ref.read(categoriesProvider.future);
    } catch (_) {
      // Re-trigger the fetch so the next tap has a fresh chance.
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: c.red,
          content: const Text(
            'Impossible de charger les catégories. Réessaie.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    final picked = await showDidoBottomSheet<Category>(
      context: context,
      title: 'Choisir une catégorie',
      child: categories.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Text(
                'Aucune catégorie pour le moment.\nAjoute-en depuis Réglages → Catégories.',
                style: context.typography.body.copyWith(color: c.fg2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < categories.length; i++) ...[
                  DidoScaleTap(
                    onTap: () => Navigator.of(context).pop(categories[i]),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 14,
                      ),
                      child: Text(
                        categories[i].name,
                        style: context.typography.body.copyWith(color: c.fg1),
                      ),
                    ),
                  ),
                  if (i < categories.length - 1)
                    Container(height: 1, color: c.border1),
                ],
              ],
            ),
    );
    if (picked != null) {
      setState(() {
        _selectedCategoryId = picked.id;
        _selectedCategoryName = picked.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final addState = ref.watch(addProductProvider);
    final isLoading = addState.status == AddProductStatus.loading;

    ref.listen(addProductProvider, (_, next) {
      if (next.status == AddProductStatus.success) {
        ref.read(productListProvider.notifier).refresh();
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: c.surface0,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  context.spacing.space4,
                  context.spacing.space3,
                  context.spacing.space4,
                  context.spacing.space4,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PhotoPicker(image: _selectedImage, onTap: _pickImage),
                      SizedBox(height: context.spacing.space6),
                      const _SectionTitle('Type de produit'),
                      SizedBox(height: context.spacing.space2),
                      DidoSegmented(
                        segments: const ['Produit standard', 'Pack'],
                        activeIndex: _isBundle ? 1 : 0,
                        onSegmentTap: (i) => setState(() => _isBundle = i == 1),
                      ),
                      SizedBox(height: context.spacing.space6),
                      const _SectionTitle('Nom du produit *'),
                      SizedBox(height: context.spacing.space2),
                      _CardField(
                        controller: _nameController,
                        hint: "ex. Robe d'été bleue",
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nom requis'
                            : null,
                      ),
                      SizedBox(height: context.spacing.space6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle("Prix d'achat *"),
                                SizedBox(height: context.spacing.space2),
                                _CardField(
                                  controller: _costPriceController,
                                  hint: '45',
                                  suffix: 'TND',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d,.]'),
                                    ),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Requis';
                                    }
                                    if (double.tryParse(
                                          v.replaceAll(',', '.'),
                                        ) ==
                                        null) {
                                      return 'Invalide';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: context.spacing.space3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionTitle('Prix de vente *'),
                                SizedBox(height: context.spacing.space2),
                                _CardField(
                                  controller: _sellPriceController,
                                  hint: '90',
                                  suffix: 'TND',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[\d,.]'),
                                    ),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Requis';
                                    }
                                    final sell = double.tryParse(
                                      v.replaceAll(',', '.'),
                                    );
                                    if (sell == null) return 'Invalide';
                                    final cost =
                                        double.tryParse(
                                          _costPriceController.text.replaceAll(
                                            ',',
                                            '.',
                                          ),
                                        ) ??
                                        0;
                                    if (sell <= cost) {
                                      return "Doit être > prix d'achat";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_profitMargin > 0) ...[
                        SizedBox(height: context.spacing.space3),
                        _ProfitPreview(margin: _profitMargin, pct: _profitPct),
                      ],
                      if (!_isBundle) ...[
                        SizedBox(height: context.spacing.space6),
                        StockSettingsBackorderCard(
                          title: 'Ce produit a des variantes',
                          subtitle: 'Couleurs, tailles, formats…',
                          value: _hasVariants,
                          onChanged: (v) => setState(() {
                            _hasVariants = v;
                            if (!v) _variants.clear();
                          }),
                        ),
                        if (!_hasVariants) ...[
                          SizedBox(height: context.spacing.space6),
                          const _SectionTitle('Stock initial *'),
                          SizedBox(height: context.spacing.space2),
                          _CardField(
                            controller: _stockController,
                            hint: '10',
                            suffix: 'unités',
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requis';
                              if (int.tryParse(v) == null) return 'Invalide';
                              return null;
                            },
                          ),
                          SizedBox(height: context.spacing.space6),
                          const _SectionTitle("Seuil d'alerte stock"),
                          SizedBox(height: context.spacing.space2),
                          StockQuantityStepper(
                            value: _lowStockThreshold,
                            min: 1,
                            max: 999,
                            compact: true,
                            onChanged: (v) =>
                                setState(() => _lowStockThreshold = v),
                          ),
                          SizedBox(height: context.spacing.space2),
                          Text(
                            "Tu seras alerté(e) quand le stock disponible "
                            "tombe à ce niveau.",
                            style: context.typography.caption.copyWith(
                              color: c.fg3,
                            ),
                          ),
                          SizedBox(height: context.spacing.space6),
                          StockSettingsBackorderCard(
                            title: 'Accepter backorders',
                            subtitle: 'Vendre même si en rupture',
                            value: _backorderEnabled,
                            onChanged: (v) =>
                                setState(() => _backorderEnabled = v),
                          ),
                        ] else ...[
                          SizedBox(height: context.spacing.space6),
                          VariantsSection(
                            initialVariants: _variants,
                            onChanged: (next) => setState(() {
                              _variants
                                ..clear()
                                ..addAll(next);
                            }),
                          ),
                          SizedBox(height: context.spacing.space6),
                          StockSettingsBackorderCard(
                            title: 'Accepter backorders',
                            subtitle:
                                'Vendre même si en rupture (toutes variantes)',
                            value: _backorderEnabled,
                            onChanged: (v) =>
                                setState(() => _backorderEnabled = v),
                          ),
                        ],
                      ],
                      SizedBox(height: context.spacing.space6),
                      const _SectionTitle('Catégorie'),
                      SizedBox(height: context.spacing.space2),
                      _CategoryDropdown(
                        selectedName: _selectedCategoryName,
                        onTap: _pickCategory,
                      ),
                      if (_isBundle) ...[
                        SizedBox(height: context.spacing.space6),
                        BundleComponentsSection(
                          initialComponents: _bundleComponents,
                          onChanged: (next) => setState(() {
                            _bundleComponents
                              ..clear()
                              ..addAll(next);
                          }),
                        ),
                      ],
                      SizedBox(height: context.spacing.space6),
                      const _SectionTitle('Description'),
                      SizedBox(height: context.spacing.space2),
                      _CardField(
                        controller: _descriptionController,
                        hint: 'Description du produit…',
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                      ),
                      if (addState.error != null) ...[
                        SizedBox(height: context.spacing.space4),
                        _ErrorBanner(message: addState.error!),
                      ],
                      SizedBox(height: context.spacing.space6),
                    ],
                  ),
                ),
              ),
            ),
            _StickyFooter(
              loading: isLoading,
              enabled: _canSave,
              onSave: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Header
// ════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.space4,
        context.spacing.space3,
        context.spacing.space4,
        context.spacing.space3,
      ),
      child: Row(
        children: [
          _ScaleTap(
            pressedScale: 0.92,
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
          SizedBox(width: context.spacing.space3),
          Expanded(
            child: Text(
              'Nouveau produit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typography.h2.copyWith(color: c.fg1),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Photo picker
// ════════════════════════════════════════════════════════════
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.image, required this.onTap});
  final XFile? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
          border: Border.all(color: c.border1),
        ),
        clipBehavior: Clip.antiAlias,
        child: image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  FutureBuilder<Uint8List>(
                    future: image!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: c.fg1,
                        borderRadius: BorderRadius.circular(
                          context.radius.radiusInput,
                        ),
                      ),
                      child: Text(
                        'Changer la photo',
                        style: context.typography.bodySmallMd.copyWith(
                          color: c.surface0,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: c.surface3,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: c.fg2,
                      size: 24,
                    ),
                  ),
                  SizedBox(height: context.spacing.space2),
                  Text(
                    'Ajouter une photo',
                    style: context.typography.bodyMd.copyWith(color: c.fg2),
                  ),
                  SizedBox(height: context.spacing.space1),
                  Text(
                    'Toucher pour choisir une photo',
                    style: context.typography.bodySmall.copyWith(color: c.fg3),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PhotoSourceSheet extends StatelessWidget {
  const _PhotoSourceSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.radius.radiusSheet),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.spacing.space4,
            context.spacing.space2,
            context.spacing.space4,
            context.spacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: context.spacing.space4),
              Text(
                'Ajouter une photo',
                style: context.typography.h3.copyWith(color: c.fg1),
              ),
              SizedBox(height: context.spacing.space4),
              Row(
                children: [
                  Expanded(
                    child: _PhotoSourceTile(
                      icon: Icons.camera_alt_rounded,
                      label: 'Appareil photo',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  SizedBox(width: context.spacing.space3),
                  Expanded(
                    child: _PhotoSourceTile(
                      icon: Icons.photo_library_rounded,
                      label: 'Galerie',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.space4,
          vertical: context.spacing.space4,
        ),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(context.radius.radiusCard),
        ),
        child: Column(
          children: [
            Icon(icon, color: c.fg1, size: 24),
            SizedBox(height: context.spacing.space2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.typography.bodyMd.copyWith(color: c.fg1),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Profit preview
// ════════════════════════════════════════════════════════════
class _ProfitPreview extends StatelessWidget {
  const _ProfitPreview({required this.margin, required this.pct});
  final double margin;
  final double pct;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space4,
        vertical: context.spacing.space3,
      ),
      decoration: BoxDecoration(
        color: c.greenTint12,
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded, color: c.greenFg, size: 18),
          SizedBox(width: context.spacing.space2),
          Expanded(
            child: Text(
              'Bénéfice par vente : +${margin.toStringAsFixed(0)} TND (${pct.toStringAsFixed(1)} %)',
              style: context.typography.bodySmallMd.copyWith(color: c.greenFg),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Section title
// ════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.typography.label.copyWith(color: context.colors.fg3),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Card field — TextFormField wrapped in a bordered card
// ════════════════════════════════════════════════════════════
class _CardField extends StatelessWidget {
  const _CardField({
    required this.controller,
    required this.hint,
    this.suffix,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.maxLines = 1,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final String? suffix;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border.all(color: c.border1),
        borderRadius: BorderRadius.circular(context.radius.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        validator: validator,
        style: context.typography.input.copyWith(color: c.fg1),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: context.typography.input.copyWith(color: c.fg3),
          suffixText: suffix,
          suffixStyle: context.typography.bodyMd.copyWith(color: c.fg3),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.spacing.space4,
            vertical: context.spacing.space3,
          ),
          isDense: true,
          errorStyle: context.typography.bodySmall.copyWith(color: c.redFg),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Error banner
// ════════════════════════════════════════════════════════════
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.spacing.space3),
      decoration: BoxDecoration(
        color: c.redTint12,
        borderRadius: BorderRadius.circular(context.radius.radiusInput),
      ),
      child: Text(
        message,
        style: context.typography.bodySmall.copyWith(color: c.redFg),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Sticky footer
// ════════════════════════════════════════════════════════════
class _StickyFooter extends StatelessWidget {
  const _StickyFooter({
    required this.loading,
    required this.enabled,
    required this.onSave,
  });

  final bool loading;
  final bool enabled;
  final VoidCallback onSave;

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
        context.spacing.space4,
        context.spacing.space3,
        context.spacing.space4,
        context.spacing.space3 + bottomInset,
      ),
      child: DidoButton.primary(
        label: 'Enregistrer',
        loading: loading,
        enabled: enabled,
        fullWidth: true,
        onPressed: onSave,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// Tap feedback (TODO(extract))
// ════════════════════════════════════════════════════════════
class _ScaleTap extends StatefulWidget {
  const _ScaleTap({
    required this.child,
    required this.onTap,
    this.pressedScale = 0.98,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  bool _pressed = false;
  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) {
              _set(true);
              HapticFeedback.lightImpact();
            },
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              _set(false);
              widget.onTap!();
            },
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: context.motion.tap,
        curve: context.motion.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.selectedName, required this.onTap});

  final String? selectedName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface1,
          border: Border.all(color: c.border1, width: 1),
          borderRadius: BorderRadius.circular(context.radius.radiusInput),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedName ?? "Sélectionner une catégorie",
                style: context.typography.body.copyWith(
                  color: selectedName == null ? c.fg3 : c.fg1,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: c.fg3),
          ],
        ),
      ),
    );
  }
}
