import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_border_radius.dart';
import '../../../../core/theme/app_theme_extension.dart';
import '../../../../core/utils/millimes_formatter.dart';
import '../providers/product_provider.dart';

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
  final _categoryController = TextEditingController();

  XFile? _selectedImage;
  bool _showAdvanced = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Add Photo',
                style: AppTypography.h4.copyWith(
                  color: context.appTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _ImageSourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _ImageSourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  int _parseTnd(String value) {
    final tnd = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return MillimesFormatter.toMillimes(tnd);
  }

  double get _profitMargin {
    final cost = double.tryParse(
            _costPriceController.text.replaceAll(',', '.')) ??
        0;
    final sell = double.tryParse(
            _sellPriceController.text.replaceAll(',', '.')) ??
        0;
    return sell - cost;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(addProductProvider.notifier).createProduct(
          name: _nameController.text.trim(),
          baseCostPrice: _parseTnd(_costPriceController.text),
          baseSellPrice: _parseTnd(_sellPriceController.text),
          initialStock: int.tryParse(_stockController.text) ?? 0,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _categoryController.text.trim().isEmpty
              ? null
              : _categoryController.text.trim().toLowerCase(),
          imagePath: _selectedImage?.path,
        );
  }

  @override
  Widget build(BuildContext context) {
    final addState = ref.watch(addProductProvider);
    final isLoading = addState.status == AddProductStatus.loading;

    ref.listen(addProductProvider, (_, next) {
      if (next.status == AddProductStatus.success) {
        // Refresh product list
        ref.read(productListProvider.notifier).refresh();
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xl,
                AppSpacing.screenHorizontal,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.appSurfaceL2,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Add Product',
                    style: AppTypography.h2.copyWith(
                      color: context.appTextPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Form ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Photo picker ─────────────────
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: context.appSurfaceL2,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: context.appBorder,
                              width: 1.5,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        File(_selectedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        bottom: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    AppRadius.full),
                                          ),
                                          child: Text(
                                            'Change Photo',
                                            style:
                                                AppTypography.label.copyWith(
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: context.appBrandLight,
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.full),
                                      ),
                                      child: Icon(
                                        Icons.add_a_photo_rounded,
                                        color: context.appBrand,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Add Product Photo',
                                      style: AppTypography.body.copyWith(
                                        color: context.appBrand,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to choose from camera or gallery',
                                      style: AppTypography.caption.copyWith(
                                        color: context.appTextTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Product Name ─────────────────
                      _FieldLabel(label: 'Product Name *'),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        style: AppTypography.body.copyWith(
                          color: context.appTextPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Blue Summer Dress',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Product name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Price Row ────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FieldLabel(label: 'Cost Price *'),
                                const SizedBox(height: AppSpacing.xs),
                                TextFormField(
                                  controller: _costPriceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textInputAction: TextInputAction.next,
                                  style: AppTypography.body.copyWith(
                                    color: context.appTextPrimary,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[\d,.]')),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: '45',
                                    suffixText: 'TND',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    if (double.tryParse(
                                            v.replaceAll(',', '.')) ==
                                        null) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FieldLabel(label: 'Sell Price *'),
                                const SizedBox(height: AppSpacing.xs),
                                TextFormField(
                                  controller: _sellPriceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textInputAction: TextInputAction.next,
                                  style: AppTypography.body.copyWith(
                                    color: context.appTextPrimary,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[\d,.]')),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: '90',
                                    suffixText: 'TND',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    final sell = double.tryParse(
                                        v.replaceAll(',', '.'));
                                    if (sell == null) return 'Invalid';
                                    final cost = double.tryParse(
                                            _costPriceController.text
                                                .replaceAll(',', '.')) ??
                                        0;
                                    if (sell <= cost) {
                                      return 'Must be > cost';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // ── Live profit preview ──────────
                      if (_profitMargin > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.trending_up_rounded,
                                color: AppColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Profit per sale: +${_profitMargin.toStringAsFixed(0)} TND',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.md),

                      // ── Stock ────────────────────────
                      _FieldLabel(label: 'Initial Stock *'),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        style: AppTypography.body.copyWith(
                          color: context.appTextPrimary,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          hintText: '10',
                          suffixText: 'units',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (int.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Advanced (optional) ──────────
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showAdvanced = !_showAdvanced),
                        child: Row(
                          children: [
                            Icon(
                              _showAdvanced
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: context.appBrand,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showAdvanced
                                  ? 'Hide optional fields'
                                  : 'Add category & description',
                              style: AppTypography.body.copyWith(
                                color: context.appBrand,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_showAdvanced) ...[
                        const SizedBox(height: AppSpacing.md),

                        // Category
                        _FieldLabel(label: 'Category'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _categoryController,
                          textInputAction: TextInputAction.next,
                          style: AppTypography.body.copyWith(
                            color: context.appTextPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g. dresses, shoes, accessories',
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Description
                        _FieldLabel(label: 'Description'),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          style: AppTypography.body.copyWith(
                            color: context.appTextPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Optional product description...',
                          ),
                        ),
                      ],

                      // ── Error ────────────────────────
                      if (addState.error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            addState.error!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxl),

                      // ── Save button ──────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.appBrand,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor:
                                context.appBrand.withValues(alpha: 0.3),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Text(
                                  'Save Product',
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable components ────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.body.copyWith(
        color: context.appTextPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ImageSourceOption extends StatelessWidget {
  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.appSurfaceL2,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.appBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: context.appBrand, size: 28),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: context.appTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}