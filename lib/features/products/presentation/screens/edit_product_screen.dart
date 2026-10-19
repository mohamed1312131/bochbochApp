import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../../../../shared/widgets/dido_bottom_sheet.dart';
import '../../../../shared/widgets/dido_button.dart';
import '../../../../shared/widgets/dido_product_image.dart';
import '../../../../shared/widgets/dido_scale_tap.dart';
import '../../../stock/domain/stock_models.dart';
import '../../../stock/presentation/providers/stock_provider.dart';
import '../../../stock/presentation/widgets/stock_quantity_stepper.dart';
import '../../../stock/presentation/widgets/stock_settings_backorder_card.dart';
import '../../domain/product_models.dart';
import '../providers/product_provider.dart';
import '../widgets/bundle_component_draft.dart';
import '../widgets/bundle_components_section.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  const EditProductScreen({super.key, required this.product});
  final Product product;

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellPriceController;
  late final TextEditingController _categoryController;

  XFile? _newImage;
  bool _isLoading = false;
  String? _error;

  // ── Stock-aware fields (chunk 8a) ──
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  late int _lowStockThreshold;
  late bool _backorderEnabled;
  bool _categoriesHydrated = false;

  // ── Bundle mode (chunk 9-C) ──
  late bool _isBundle;
  bool _isBundleLoading = false;
  // Loaded once from `getBundle` then handed to BundleComponentsSection
  // as `initialComponents`. Subsequent mutations are received back via
  // onChanged and stored here for the save handler — single source of
  // truth, no parallel sync from parent into child.
  List<BundleComponentDraft>? _bundleInitial;
  List<BundleComponentDraft> _bundleComponents = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _descriptionController = TextEditingController(text: p.description ?? '');
    _costPriceController = TextEditingController(
      text: MillimesFormatter.toTnd(p.baseCostPrice).toStringAsFixed(0),
    );
    _sellPriceController = TextEditingController(
      text: MillimesFormatter.toTnd(p.baseSellPrice).toStringAsFixed(0),
    );
    _categoryController = TextEditingController(text: p.category ?? '');

    _selectedCategoryId = p.categoryId;
    _selectedCategoryName = p.categoryId != null ? p.category : null;

    final firstActive = p.variants
        .where((v) => v.isActive)
        .cast<ProductVariant?>()
        .firstWhere((_) => true, orElse: () => null);
    _lowStockThreshold = firstActive?.lowStockThreshold ?? 3;
    _backorderEnabled = firstActive?.backorderEnabled ?? false;

    _isBundle = p.effectiveIsBundle;
    if (_isBundle) {
      _isBundleLoading = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadBundleComponents(),
      );
    }

    _nameController.addListener(_rebuild);
    _costPriceController.addListener(_rebuild);
    _sellPriceController.addListener(_rebuild);
  }

  Future<void> _loadBundleComponents() async {
    try {
      final bundle = await ref
          .read(stockRepositoryProvider)
          .getBundle(widget.product.id);
      if (!mounted) return;
      final drafts = bundle.components
          .map(
            (c) => BundleComponentDraft(
              variantId: c.componentVariantId,
              productName: c.componentProductName,
              sku: c.componentSku,
              componentCost: c.componentCost,
              qtyPerBundle: c.qtyPerBundle,
            ),
          )
          .toList();
      setState(() {
        _bundleInitial = drafts;
        _bundleComponents = List.from(drafts);
        _isBundleLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bundleInitial = [];
        _isBundleLoading = false;
      });
    }
  }

  /// Fuzzy-match product.category (free text) against the categories
  /// list once it loads. Runs only when categoryId is null and the
  /// product has a free-text category. Idempotent across rebuilds.
  void _hydrateCategoryFromFreeText(List<Category> categories) {
    if (_categoriesHydrated) return;
    _categoriesHydrated = true;
    final p = widget.product;
    if (p.categoryId != null) return;
    if (p.category == null || p.category!.trim().isEmpty) return;
    final needle = p.category!.trim().toLowerCase();
    for (final cat in categories) {
      if (cat.name.trim().toLowerCase() == needle) {
        setState(() {
          _selectedCategoryId = cat.id;
          _selectedCategoryName = cat.name;
        });
        return;
      }
    }
  }

  Future<void> _pickCategory() async {
    final categories =
        ref.read(categoriesProvider).valueOrNull ?? const <Category>[];
    if (categories.isEmpty) return;
    final picked = await showDidoBottomSheet<Category>(
      context: context,
      title: 'Choisir une catégorie',
      child: Column(
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
                  style: context.typography.body.copyWith(
                    color: context.colors.fg1,
                  ),
                ),
              ),
            ),
            if (i < categories.length - 1)
              Container(height: 1, color: context.colors.border1),
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

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _categoryController.dispose();
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
    // Block save while bundle components are still loading so the
    // form can't submit with stale or empty `_bundleComponents`.
    if (_isBundle && _isBundleLoading) return false;
    return true;
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PhotoSourceSheet(),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _newImage = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(productRepositoryProvider);

      final freeText = _categoryController.text.trim();
      await repo.updateProduct(
        widget.product.id,
        name: _nameController.text.trim(),
        baseCostPrice: _parseTnd(_costPriceController.text),
        baseSellPrice: _parseTnd(_sellPriceController.text),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category:
            _selectedCategoryName ??
            (freeText.isEmpty ? null : freeText.toLowerCase()),
        categoryId: _selectedCategoryId,
        lowStockThreshold: _isBundle ? null : _lowStockThreshold,
        backorderEnabled: _isBundle ? null : _backorderEnabled,
      );

      if (_isBundle) {
        await ref
            .read(stockRepositoryProvider)
            .upsertBundle(widget.product.id, [
              for (final c in _bundleComponents)
                BundleComponent(
                  componentVariantId: c.variantId,
                  componentProductName: c.productName,
                  componentSku: c.sku,
                  qtyPerBundle: c.qtyPerBundle,
                  componentCost: c.componentCost,
                ),
            ]);
      }

      if (_newImage != null) {
        try {
          final imageData = await repo.uploadImage(_newImage!.path);
          await repo.attachImage(
            widget.product.id,
            cloudinaryPublicId: imageData['cloudinaryPublicId']!,
            url: imageData['url']!,
            isPrimary: true,
          );
        } catch (_) {
          // Non-fatal
        }
      }

      ref.read(productListProvider.notifier).refresh();
      ref.invalidate(productDetailProvider(widget.product.id));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final categoriesAsync = ref.watch(categoriesProvider);
    // Idempotent build-time hydration: `_hydrateCategoryFromFreeText`
    // self-guards via `_categoriesHydrated`, so this only mutates state
    // on the first build that sees a `data` value. Slightly less
    // idiomatic than `ref.listen` in initState, but the guard keeps it
    // safe and the mutation is a one-shot.
    categoriesAsync.whenData(_hydrateCategoryFromFreeText);
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
                      _PhotoPicker(
                        newImage: _newImage,
                        existingImageUrl: widget.product.primaryImageUrl,
                        onTap: _pickImage,
                      ),
                      SizedBox(height: context.spacing.space6),
                      const _SectionTitle('Nom du produit *'),
                      SizedBox(height: context.spacing.space2),
                      _CardField(
                        controller: _nameController,
                        hint: 'Nom du produit',
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
                                  hint: '0',
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
                                  hint: '0',
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
                      ],
                      if (_isBundle) ...[
                        SizedBox(height: context.spacing.space6),
                        if (_isBundleLoading)
                          Padding(
                            padding: EdgeInsets.all(context.spacing.space4),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else
                          BundleComponentsSection(
                            initialComponents: _bundleInitial ?? const [],
                            onChanged: (next) => _bundleComponents = next,
                          ),
                      ],
                      SizedBox(height: context.spacing.space6),
                      const _SectionTitle('Catégorie'),
                      SizedBox(height: context.spacing.space2),
                      _CategoryDropdown(
                        selectedName: _selectedCategoryName,
                        onTap: _pickCategory,
                      ),
                      SizedBox(height: context.spacing.space6),
                      const _SectionTitle('Description'),
                      SizedBox(height: context.spacing.space2),
                      _CardField(
                        controller: _descriptionController,
                        hint: 'Description du produit…',
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 3,
                      ),
                      if (_error != null) ...[
                        SizedBox(height: context.spacing.space4),
                        _ErrorBanner(message: _error!),
                      ],
                      SizedBox(height: context.spacing.space6),
                    ],
                  ),
                ),
              ),
            ),
            _StickyFooter(
              loading: _isLoading,
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
              'Modifier le produit',
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
// Photo picker — handles new image, existing image, or empty
// ════════════════════════════════════════════════════════════
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.newImage,
    required this.existingImageUrl,
    required this.onTap,
  });

  final XFile? newImage;
  final String? existingImageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasImage = newImage != null || existingImageUrl != null;
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
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  if (newImage != null)
                    FutureBuilder<Uint8List>(
                      future: newImage!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      },
                    )
                  else
                    DidoProductImage(
                      imageUrl: existingImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_) => Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: c.fg3,
                          size: 32,
                        ),
                      ),
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
                'Changer la photo',
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
        padding: EdgeInsets.all(context.spacing.space4),
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
// Card field
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
        label: 'Enregistrer les modifications',
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
